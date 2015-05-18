toGRanges <- function(data, format=c("BED", "GFF", "RangedData", "MACS", "others"), 
                      header=FALSE, comment.char="#", colNames=NULL, ...)
{
  if (missing(data)){
    stop("data is required!")
  }
  format <- match.arg(format)
  if (inherits(data, "character")){
    tab5rows <- read.table(data, header=header, ..., nrows=5)
    classes <- sapply(tab5rows, class)
      if(format=="BED"){##check class of column 2 and 3
          if(classes[2]!="integer"||classes[3]!="integer")
          stop("No valid data passed in. For example a data frame as BED format file with at least 3 fields
          in the order of: chromosome, start and end. Optional fields are name, score and strand etc.
          Column 2 and 3 must be integer. 
          Please refer to http://genome.ucsc.edu/FAQ/FAQformat#format1 for details.")
          if(!is.na(classes[5])) classes[5] <- "numeric"
      }else{
          if(format=="GFF"){##check class of column 4 and 5
              if(classes[4]!="integer"||classes[5]!="integer")
              stop("No valid data passed in. For example a data frame as GFF format file with 9 fields
              in the order of: seqname, source, feature, start, end, score, strand, frame and group.
              Column 4 and 5 must be integer.
              Please refer to http://genome.ucsc.edu/FAQ/FAQformat#format1 for details.")
          }else{
              if(format=="MACS"){
                  header <- TRUE
                  comment.char <- "#"
              }else{
                  if(header && is.null(colNames)){ ## format=="others"
                      colNames <- colnames(tab5rows)
                  }
              }
          }
      }
      if(format=="BED" && length(classes)>12) classes[13:length(classes)] <- rep("NULL", length(classes)-12)
    data <- read.table(data, header=header, comment.char=comment.char, ..., colClasses=classes)
    rm(list=c("tab5rows", "classes"))
    colNames <- switch(format,
                      BED=c("space", "start", "end", "names", "score", "strand", "thickStart", "thickEnd", "itemRgb", "blockCount", "blockSizes", "blockStarts"),
                      GFF=c("space", "source", "names", "start", "end", "score", "strand", "frame", "group"),
                      MACS=c("space", "start", "end", "length", "summit", "tags", "qvalue", "fold_enrichment", "FDR"),
                      others=colNames)
  }
  if (inherits(data, "RangedData")){
    ##RangedData to data.frame
    data <- as.data.frame(data)
    ##data colNames should be 
    ##space, start, end, width, names, ...
    data$width <- NULL
    colNames <- colnames(data)
  }
  if ((class(data) != "data.frame") || dim(data)[2] <3)
  {
    stop("No valid data passed in. For example a data frame as BED format file with at least 3 fields 
         in the order of: chromosome, start and end. Optional fields are name, score and strand etc. 
         Please refer to http://genome.ucsc.edu/FAQ/FAQformat#format1 for details.")
  }
  if(is.null(colNames)) colNames <- colnames(data)
  colNames_space <- tolower(colNames) %in% c("space", "seqnames", "chr", "chrom", "chromosome", "chromosomes")
  if(length(sum(colNames_space))==1){
      colNames[colNames_space] <- "space"
  }
  colNames <- gsub("^start$", "start", colNames, ignore.case=TRUE)
  colNames <- gsub("^end$", "end", colNames, ignore.case=TRUE)
  if(!all(c("space","start","end") %in% colNames)){
    stop("colname must contain space/seqnames, start and end.")
  }
  if(length(colNames)<ncol(data)) stop("the length of colNames is less than number of columns of data")
  colnames(data) <- colNames[1:ncol(data)]
#  gc(verbose=FALSE, reset=TRUE)
  
  getCol <- function(pattern, words, default){
    ss <- grep(pattern, colnames(data), ignore.case=TRUE)
    if(length(ss)>1) stop(paste("input data has multiple columns for",words,"information"))
    if(length(ss)==1){
      re <- data[,ss]
      data[, ss] <<- NULL 
    }else{
      re <- default
    }
    re
  }
  ##prepare strand
  strand <- getCol("^strand$", "strand", "*")
  strand <- formatStrand(strand)
#  gc(verbose=FALSE, reset=TRUE)
  
  ##prepare name, memory comsume step. TODO, change it.
  names <- getCol("^names$", "names", NA)
  if(any(is.na(names)) || any(duplicated(names))) {
      message("duplicated or NA names found. Rename all the names by numbers.")
##      names <- formatC(1:nrow(data), width=nchar(nrow(data)), flag='0')
      ## formatC has memory leak
      n <- nrow(data)
      names <- sprintf(paste("X%0",nchar(as.character(n)),"d", sep=""), 1:n)
  }
  names <- make.names(names)
  
  ##prepare score
#   score <- getCol("^score$", "score", 1L)
#   if(length(score)==1) score <- rep(1, nrow(data))
#   if(all(is.na(score))) score <- rep(1, nrow(data))
#   score <- as.numeric(as.character(score))
  
  ##prepare start, end, seqnames
  start <- data$start
  end <- data$end
  seqnames <- data$space
  if(!is.numeric(start[1])) start <- as.numeric(as.character(start))
  if(!is.numeric(end[1])) end <- as.numeric(as.character(end))
  if(!is.character(seqnames[1])) seqnames <- as.character(data$space)
  
  gr <- GRanges(seqnames=seqnames, 
          ranges=IRanges(start=start, 
                         end=end, 
                         names = names), 
          strand=strand)
  rm(list=c("start", "end", "names", "strand", "seqnames"))
  metadata <- colnames(data)
  metadata <- metadata[!metadata %in% c("seqnames", "space", "ranges", "strand", "seqlevels", 
                                        "seqlengths", "isCircular", "genome", "start", 
                                        "end", "width", "element")]
  for(col in metadata){
    mcols(gr)[,col]<-data[,col]
  }
  rm(data)
#  gc(verbose=FALSE, reset=TRUE)
  if(format=="BED"){ ## bed file is (start, end]
      start(gr) <- start(gr) + 1
  }
  gr
}