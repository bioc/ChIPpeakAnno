formatStrand <- function(strand){
  strand <- as.character(strand)
  strand.levels=levels(as.factor(strand))
  strand.allowed.characters=c("1","-1","+","-", "*")
  if(any(!strand.levels %in% strand.allowed.characters))
  {
    warning("All the characters for strand, 
            other than '1', '-1', '+', '-' and '*', 
            will be converted into '*'.")
  }
  strand[strand== "-1"] <- "-"
  strand[strand== "1"] <- "+"
  strand[!strand %in% strand.allowed.characters] <- "*"
  strand
}
###clear seqnames, the format should be chr+NUM
#' @importFrom GenomeInfoDb `seqlevels<-` `seqlevelsStyle` `seqlevelsStyle<-`
formatSeqnames <- function(from, to) {
  forceFormatSeqnames <- function(from, to){
    message("\n Try to keep the seqname style consistent.")
    seql <- seqlevels(to)
    getPrefix <- function(x, seql){
      seql <- table(c(grepl(x, seql), "TRUE", "FALSE"))
      if(seql['TRUE'] > seql['FALSE']){
        prefix <- x
      }else{
        prefix <- ""
      }
      prefix
    }
    
    prefix <- ""
    for(i in c("chr", "Chr")){
      if(prefix==""){
        prefix <- getPrefix(i, seql)
      }
    }
    if(prefix!=""){
      if(length(seqlevels(from)[grepl("^(\\d+|V?I{0,3}|IV|MT|M|X|Y)$",
                                      seqlevels(from))])>0){
        if(is(from, "GRanges")){
          seqlevels(from)[grepl("^(\\d+|V?I{0,3}|IV|MT|M|X|Y)$", seqlevels(from))] <-
            paste(prefix,
                  seqlevels(from)[grepl("^(\\d+|V?I{0,3}|IV|MT|M|X|Y)$",
                                        seqlevels(from))], sep="")
          #seqlevels(from)[seqlevels(from)=="chrMT"] <- "chrM"
        }else{
          seqnames(from)[grepl("^(\\d+|V?I{0,3}|IV|MT|M|X|Y)$", seqnames(from))] <-
            paste(prefix,
                  seqnames(from)[grepl("^(\\d+|V?I{0,3}|IV|MT|M|X|Y)$",
                                       seqnames(from))], sep="")
          #seqnames(from)[seqnames(from)=="chrMT"] <- "chrM"
        }
      }
      #if(seqlevelsStyle(from)!="UCSC") seqlevelsStyle(from) <- "UCSC"
      seqlevels(from) <- sub("^chr", prefix, seqlevels(from), 
                             ignore.case = TRUE)
    }else{
      ## remove chr
      seqlevels(from) <- sub("^chr", prefix, seqlevels(from), 
                             ignore.case = TRUE)
    }
    from
  }
  seql <- seqlevelsStyle(to)
  seqf <- seqlevelsStyle(from)
  if(!seql[1] %in% seqf){
    tried <- try({
      seqlevelsStyle(from) <- seql[1]
    })
    if(inherits(tried, "try-error")){
      from <- forceFormatSeqnames(from, to)
    }
  }
  
  seql <- seqlevelsStyle(to)
  seqf <- seqlevelsStyle(from)
  if(length(intersect(seql, seqf))==0){
    from <- forceFormatSeqnames(from, to)
  }
  from
}

getRelationship <- function(queryHits, subjectHits){
    if(!inherits(queryHits, "GRanges")) 
        stop("queryHits must be an object of GRanges")
    if(!inherits(subjectHits, "GRanges")) 
        stop("subjectHits must be an object of GRanges")
    strand <- strand(subjectHits)=="-"
    FeatureStart <- as.numeric(ifelse(strand, 
                                      end(subjectHits), 
                                      start(subjectHits)))
    FeatureEnd <- as.numeric(ifelse(strand, 
                                    start(subjectHits), 
                                    end(subjectHits)))
    PeakStart <- as.numeric(ifelse(strand, end(queryHits), 
                                   start(queryHits)))
    PeakEnd <- as.numeric(ifelse(strand, start(queryHits), end(queryHits)))
    ss <- PeakStart - FeatureStart
    ee <- PeakEnd - FeatureEnd
    se <- PeakStart - FeatureEnd
    es <- PeakEnd - FeatureStart
    upstream <- ifelse(strand, es>0, es<0)
    downstream <- ifelse(strand, se<0, se>0)
    includeFeature <- ifelse(strand, (ss>=0 & ee<=0), (ss<=0 & ee>=0))
    overlap <- ss==0 & ee==0
    inside <- ifelse(strand, (ss<=0 & ee>=0), (ss>=0 & ee<=0))
    overlapStart <- 
        ifelse(strand, (ss>0 & es<=0 & ee>=0), (ss<0 & es>=0 & ee<=0))
    overlapEnd <- 
        ifelse(strand, (ss<0 & se>=0 & ee<=0), (ss>0 & se<=0 & ee>=0))
    insideFeature <- rep(NA, length(queryHits))
    insideFeature[as.logical(includeFeature)] <- "includeFeature"
    insideFeature[as.logical(inside)] <- "inside"
    insideFeature[as.logical(overlap)] <- "overlap"
    insideFeature[as.logical(overlapEnd)] <- "overlapEnd"
    insideFeature[as.logical(downstream)] <- "downstream"
    insideFeature[as.logical(overlapStart)] <- "overlapStart"
    insideFeature[as.logical(upstream)] <- "upstream"
    shortestDistance <- apply(cbind(ss, ee, se, es), 1,
                              function(.ele) min(abs(.ele)))
    shortestDistanceToStart <- apply(cbind(ss, es), 1, 
                                     function(.ele) min(abs(.ele)))
    data.frame(insideFeature=insideFeature, 
               shortestDistance=shortestDistance, 
               ss=ss,
               distanceToStart=shortestDistanceToStart)
}
annoScore <- function(queryHits, subjectHits){
    if(!inherits(queryHits, "GRanges")) 
        stop("queryHits must be an object of GRanges")
    if(!inherits(subjectHits, "GRanges")) 
        stop("subjectHits must be an object of GRanges")
    stopifnot(length(queryHits)==length(subjectHits))
    ## jaccard index of two range
    intersection <- pintersect(queryHits, subjectHits)
    totalSize <- punion(queryHits, subjectHits, fill.gap=TRUE, ignore.strand=TRUE)
    JaccardIndex <- width(intersection)/width(totalSize)
    JaccardIndex
}
trimPeakList <- function(Peaks, ignore.strand, by, keepMetadata=FALSE){
    if (!inherits(Peaks, "GRanges")) {
        stop("No valid Peaks passed in. It needs to be GRanges object")
    }
    if(ignore.strand) {
        .gr <- paste(seqnames(Peaks), start(Peaks), end(Peaks))
    }else{
        .gr <- paste(seqnames(Peaks), start(Peaks), 
                     end(Peaks), strand(Peaks))
    }
    if(any(duplicated(.gr)))
        stop("Inputs contains duplicated ranges. 
             please recheck your inputs.")
    if(any(is.null(names(Peaks))) || 
       any(is.na(names(Peaks))) || 
       any(duplicated(names(Peaks)))) {
        message("duplicated or NA names found. 
                Rename all the names by numbers.")
        names(Peaks) <- formatC(1:length(Peaks), 
                                width=nchar(length(Peaks)), 
                                flag='0')
    }
    feature <- mcols(Peaks)$feature
    if(!keepMetadata) mcols(Peaks) <- NULL
    if(by=="feature") {
        if(is.null(feature)) 
            stop("Need feature metadata for each inputs")
        mcols(Peaks)$feature <- feature
    }
    Peaks
}

#' @importFrom S4Vectors queryHits subjectHits
vennCounts <- function(PeaksList, n, names,
                       maxgap=-1L, minoverlap=0L,
                       by=c("region", "feature", "base"), 
                       ignore.strand=TRUE, 
                       connectedPeaks=c("min", "merge", "keepAll")){
    NAME_conn_string <- "___conn___"
    PeaksList<-lapply(PeaksList, trimPeakList, by=by, 
                      ignore.strand=ignore.strand, keepMetadata=FALSE)
    if(by=="base"){
        # try coverage and then split
        # problem for coverage: can not seperate for different source
        for(i in 1:n){
            names(PeaksList[[i]]) <- 
                paste(names[i], names(PeaksList[[i]]), sep=NAME_conn_string)
        }
        names(PeaksList) <- NULL
        Peaks <- unlist(GRangesList(PeaksList))
        #if(ignore.strand) strand(Peaks) <- "*"
        #cov <- coverage(Peaks)
        disj <- disjoin(Peaks, ignore.strand=ignore.strand)
        ol <- findOverlaps(Peaks, disj, ignore.strand=ignore.strand)
        ol.query <- Peaks[queryHits(ol)]
        ol.subject <- disj[subjectHits(ol)]
        group <- gsub(paste(NAME_conn_string, ".*$", sep=""), 
                      "", 
                      names(ol.query))
        subject <- subjectHits(ol)
        ncontrasts <- n
        noutcomes <- 2^ncontrasts
        outcomes <- matrix(0,noutcomes,ncontrasts)
        colnames(outcomes) <- names
        for (j in 1:ncontrasts)
            outcomes[,j] <- rep(0:1,times=2^(j-1),each=2^(ncontrasts-j))
        gps <- split(group, subject)
        xlist <- list()
        for(i in 1:ncontrasts)
            xlist[[i]] <- 
            factor(as.numeric(sapply(gps, 
                                     function(.ele) 
                                         names[ncontrasts-i+1] %in% .ele)), 
                   levels=c(0,1))
        counts <- do.call(cbind, xlist)
        counts <- counts[, ncontrasts:1]
        counts <- counts - 1
        counts <- apply(counts, 1, base::paste, collapse="")
        idx <- apply(outcomes, 1, base::paste, collapse="")
        wids <- width(disj[as.numeric(names(gps))])
        wids <- split(wids, counts)
        wids <- wids[idx]
        names(wids) <- idx
        counts <- sapply(wids, sum)
        venn_cnt <- structure(cbind(outcomes, Counts=counts), 
                              class="VennCounts")
        return(list(venn_cnt=venn_cnt, xlist=NULL, 
                    PeaksList=PeaksList, all=all, Peaks=Peaks))
    }
    if(by=="feature"){
        features <- lapply(PeaksList, 
                           function(.ele) unique(as.character(.ele$feature)))
        all_features <- unique(unlist(features))
        all <- lapply(features, function(.f)  all_features %in% .f)
        all <- do.call(cbind, all)
        rownames(all) <- all_features
        for(j in 1:n){
            all[,j] <- ifelse(all[,j], names[j], NA)
        }
        all <- split(all, rownames(all))
        Peaks <- NULL
    }else{
        ##get all merged peaks
        for(i in 1:n){
            names(PeaksList[[i]]) <- 
                paste(names[i], names(PeaksList[[i]]), sep=NAME_conn_string)
        }
        names(PeaksList) <- NULL
        Peaks <- unlist(GRangesList(PeaksList))
        if(ignore.strand) {
            Peaks$old_strand_HH <- strand(Peaks)
            strand(Peaks) <- "*"
        }
        
        if(length(Peaks)<10000){
            ol <- as.data.frame(findOverlaps1(Peaks, maxgap=maxgap, 
                                             minoverlap=minoverlap, 
                                             select="all",
                                             drop.self=TRUE, 
                                             drop.redundant=TRUE))
            ##all connected peaks
            olm <- cbind(names(Peaks[ol[,1]]), names(Peaks[ol[,2]]))
            ## remove the overlaps from same list
            olm <- olm[sub(paste0(NAME_conn_string, ".*?$"), "", names(Peaks[ol[,1]]))!=
                         sub(paste0(NAME_conn_string, ".*?$"), "", names(Peaks[ol[,2]])), , drop=FALSE]
            edgeL <- c(split(olm[,2], olm[,1]), split(olm[,1], olm[,2]))
            nodes <- unique(as.character(olm))
            ##use graph to extract all the connected peaks
            gR <- new("graphNEL", nodes=nodes, edgeL=edgeL)
            Merged <- connectedComp(ugraph(gR))
        }else{
            Peaks.list <- split(Peaks, seqnames(Peaks))
            Merged <- lapply(Peaks.list, function(.peaks.list){
                .ol <- findOverlaps1(.peaks.list,
                                    maxgap=maxgap, minoverlap=minoverlap, 
                                    select="all",
                                    drop.self=TRUE, drop.redundant=TRUE)
                olm <- cbind(names(.peaks.list[queryHits(.ol)]), 
                             names(.peaks.list[subjectHits(.ol)]))
                ## remove the overlaps from same list
                olm <- olm[sub(paste0(NAME_conn_string, ".*?$"), "", names(.peaks.list[queryHits(.ol)]))!=
                             sub(paste0(NAME_conn_string, ".*?$"), "", names(.peaks.list[subjectHits(.ol)])), , drop=FALSE]
                edgeL <- c(split(olm[,2], olm[,1]), split(olm[,1], olm[,2]))
                nodes <- unique(as.character(olm))
                ##use graph to extract all the connected peaks
                gR <- new("graphNEL", nodes=nodes, edgeL=edgeL)
                connectedComp(ugraph(gR))
            })
            Merged <- unlist(Merged, recursive=FALSE)
            nodes <- unique(as.character(unlist(Merged)))
            rm(Peaks.list)
        }
        
        Left <- as.list(names(Peaks)[!names(Peaks) %in% nodes])
        all <- c(Merged, Left)
    }
    ##venn count
    ncontrasts <- n
    noutcomes <- 2^ncontrasts
    outcomes <- matrix(0,noutcomes,ncontrasts)
    colnames(outcomes) <- names
    for (j in 1:ncontrasts)
        outcomes[,j] <- rep(0:1,times=2^(j-1),each=2^(ncontrasts-j))
    
    xlist <- list()
    xlist1 <- list()
    ## time consuming step, FIXME!!
    ## Fixed by paste connection string before lapply 
    NAME_conn_string_wild <- paste(NAME_conn_string, ".*?$", sep="")
    all.df <- data.frame(rnames=unlist(all), 
                    groupID=rep(1:length(all), sapply(all, length)))
    all.df$tfname <- gsub(NAME_conn_string_wild, "", all.df$rnames)
    all.df.tbl <- table(all.df[, -1])
    for (i in 1:ncontrasts){
#         NAME_conn_string_contrasts_wild <- paste("^", 
#                                                  names[ncontrasts-i+1], 
#                                                  NAME_conn_string,
#                                                  sep="")
#         xlist[[i]] <- factor(as.numeric(unlist(lapply(all, function(.ele) 
#             any(grepl(NAME_conn_string_contrasts_wild, .ele))))),
#             levels=c(0,1))
        xlist[[i]] <- 
            factor(as.numeric(all.df.tbl[, names[ncontrasts-i+1]]>0), 
                   levels=c(0, 1))
        if(connectedPeaks=="merge"){
#             xlist1[[i]] <- factor(as.numeric(unlist(lapply(all, function(.ele) 
#                 any(grepl(NAME_conn_string_contrasts_wild, .ele))))),
#                 levels=c(0,1))
            xlist1[[i]] <- xlist[[i]]
        }else{ ## increase the efficency be change list to dataframe
#             xlist1[[i]] <- 
#                 factor(as.numeric(unlist(lapply(all, function(.ele) {
#                 ##count involved nodes in each group
#                 .ele <- gsub(NAME_conn_string_wild, "", .ele)
#                 .ele <- table(.ele)
#                 rep(names[ncontrasts-i+1] %in% names(.ele), min(.ele))
#             }))), levels=c(0,1))
            xlist1[[i]] <- 
                factor(as.numeric(rep(all.df.tbl[, names[ncontrasts-i+1]]>0, 
                                      apply(all.df.tbl, 1, function(.e) min(.e[.e>0])))), 
                       levels=c(0, 1))
        }
    }
    
    counts <- as.vector(table(xlist1))
    venn_cnt <- structure(cbind(outcomes, Counts=counts), class="VennCounts")
    
    if(connectedPeaks=="keepAll"){
        NAME_conn_string_wild <- paste(NAME_conn_string, ".*$", sep="")
        all.m <- lapply(all, 
                        function(.ele){gsub(NAME_conn_string_wild, "", .ele)})
        all.m <- all.m[sapply(all.m, function(.ele) length(unique(.ele))>1)]
        all.count <- ifelse(rowSums(outcomes)>1, NA, counts)
        all.count <- all.count * outcomes
        for(j in 1:ncol(all.count)){
            ylist <- list()
            for(i in 1:ncontrasts){
                ylist[[i]] <- 
                    factor(as.numeric(unlist(lapply(all.m, function(.ele){
                    .ele <- table(.ele)
                    times <- .ele[colnames(all.count)[j]]
                    if(is.na(times)) times <- 0
                    rep(names[ncontrasts-i+1] %in% names(.ele), times)
                }))), levels=c(0,1))
            }
            all.count[is.na(all.count[,j]),j] <- 
                as.vector(table(ylist))[is.na(all.count[,j])]
        }
        colnames(all.count) <- paste("count", colnames(all.count), sep=".")
        venn_cnt <- structure(cbind(outcomes, Counts=counts, all.count), 
                              class="VennCounts")
    }
    
    return(list(venn_cnt=venn_cnt, xlist=xlist, 
                PeaksList=PeaksList, all=all, 
                Peaks=Peaks))
}

findOverlaps1 <- function(query, subject, maxgap=-1L,
                          minoverlap=0L, ...){
  if(minoverlap[1]>0 && minoverlap[1]<1){
    if(missing(subject)){
      hits <- findOverlaps(query = query, 
                           minoverlap = 0L,
                           maxgap = -1L,
                           ...)
      overlaps <- pintersect(query[queryHits(hits)],
                             query[subjectHits(hits)],
                             ignore.strand = TRUE)
      percentOverlap0 <- width(overlaps)/width(query[queryHits(hits)])
      percentOverlap1 <- width(overlaps)/width(query[subjectHits(hits)])
      percentOverlap <- ifelse(
        percentOverlap0>percentOverlap1,
        percentOverlap0, percentOverlap1
      )
    }else{
      hits <- findOverlaps(query = query, 
                           subject = subject,
                           minoverlap = 0L,
                           maxgap = -1L,
                           ...)
      overlaps <- pintersect(query[queryHits(hits)],
                             subject[subjectHits(hits)],
                             ignore.strand = TRUE)
      percentOverlap0 <- width(overlaps)/width(query[queryHits(hits)])
      percentOverlap1 <- width(overlaps)/width(subject[subjectHits(hits)])
      percentOverlap <- ifelse(
        percentOverlap0>percentOverlap1,
        percentOverlap0, percentOverlap1
      )
    }
    hits[percentOverlap>=minoverlap]
  }else{
    if(missing(subject)){
      findOverlaps(query = query,
                   maxgap = maxgap,
                   minoverlap = minoverlap,
                   ...)
    }else{
      findOverlaps(query = query,
                   subject = subject,
                   maxgap = maxgap,
                   minoverlap = minoverlap,
                   ...)
    }
  }
}
#' TxDb object to GRanges
#' 
#' convert TxDb object to GRanges
#' @param ranges an Txdb object
#' @param feature feature type, could be geneModel, gene, exon, 
#' transcript, CDS, fiveUTR, threeUTR, microRNA, and tRNA
#' @param OrganismDb org db object
#' @importFrom GenomicFeatures exonsBy cdsBy fiveUTRsByTranscript 
#' threeUTRsByTranscript genes exons transcripts cds microRNAs tRNAs
#' @importFrom AnnotationDbi select
TxDb2GR <- function(ranges, feature, OrganismDb){
    switch(feature,
           geneModel={
               exon <- exonsBy(ranges, "tx", use.names=TRUE)
               tids <- rep(names(exon), elementNROWS(exon))
               exon <- unlist(exon, use.names=FALSE)
               if(length(exon)){
                   exon$tx_name <- tids
                   exon$feature_type <- "ncRNA"
                   cds <- cdsBy(ranges, "tx", use.names=TRUE)
                   tids <- 
                       rep(names(cds), elementNROWS(cds))
                   cds <- unlist(cds)
                   if(length(cds)){
                       mcols(cds) <- NULL
                       cds$tx_name <- tids
                       cds$feature_type <- "CDS"
                   }
                   utr5 <- 
                       fiveUTRsByTranscript(ranges,
                                            use.names=TRUE)
                   tids <- rep(names(utr5), 
                               elementNROWS(utr5))
                   utr5 <- unlist(utr5)
                   if(length(utr5)){
                       mcols(utr5) <- NULL
                       utr5$tx_name <- tids
                       utr5$feature_type <- "5UTR"
                   }
                   utr3 <- 
                       threeUTRsByTranscript(ranges,
                                             use.names=TRUE)
                   tids <- rep(names(utr3), 
                               elementNROWS(utr3))
                   utr3 <- unlist(utr3)
                   if(length(utr3)){
                       mcols(utr3) <- NULL
                       utr3$tx_name <- tids
                       utr3$feature_type <- "3UTR"
                   }
                   anno <- c(cds, utr5, utr3)
                   left <- exon[!(exon$tx_name %in% anno$tx_name)]
                   ##check logical, anno covered all annotation
                   right <- exon[exon$tx_name %in% anno$tx_name]
                   rd1 <- reduce(anno)
                   rd2 <- reduce(right)
                   if(!identical(rd1, rd2)){
                       stop("some annotation is missing! bug!")
                   }
                   mcols(left) <- 
                       mcols(left)[, 
                                   c("tx_name", "feature_type")]
                   exon <- c(left, anno) ## merge ncRNA with anno
                   if(!missing(OrganismDb)){
                       if(inherits(OrganismDb, c("OrganismDb"))){
                         tried <- try({
                           symbol <- select(OrganismDb, 
                                            keys=unique(exon$tx_name),
                                            columns="SYMBOL",
                                            keytype="TXNAME")
                           })
                         if(inherits(tried, "try-error")){
                           symbol <- NULL
                         }
                         if(length(symbol)>0){
                           exon$symbol <- 
                             symbol[match(exon$tx_name, 
                                          symbol[, 1]),
                                    "SYMBOL"]
                         }
                       }else{
                           message("OrganismDb must be an object of OrganismDb")
                       }
                   }
                   ## sort exon
                   exon <- exon[order(exon$tx_name)]
                   ### get each tx_name first start pos
                   tids <- rle(exon$tx_name)
                   tids$values <- 
                       tapply(start(exon), exon$tx_name, min)
                   tids <- inverse.rle(tids)
                   exon <- 
                       exon[order(as.character(seqnames(exon)),
                                  tids, 
                                  start(exon))]
                   names(exon) <- formatC(1:length(exon), 
                                          width=nchar(as.character(length(exon))),
                                          flag="0")
               }
               exon
           },
           gene={
               g <- genes(ranges, columns="gene_id")
               names(g) <- g$gene_id
               g$gene_id <- NULL
               g
           },
           exon={
               e <- exons(ranges, 
                          columns=c("exon_id", 
                                    "tx_name", 
                                    "gene_id"))
               if(length(e)){
                   names(e) <- e$exon_id
                   e$exon_id <- NULL
               }
               e
           },
           transcript={
               t <- transcripts(ranges,
                                columns=c("tx_id",
                                          "tx_name",
                                          "gene_id"))
               if(length(t)){
                   names(t) <- t$tx_id
                   t$tx_id <- NULL
               }
               t
           },
           CDS={
               c <- cds(ranges, 
                        columns=c("cds_id",
                                  "tx_name",
                                  "gene_id"))
               if(length(c)){
                   names(c) <- c$cds_id
                   c$cds_id <- NULL
               }
               c
           },
           fiveUTR={
               u <- fiveUTRsByTranscript(ranges,
                                         use.name=TRUE)
               tids <- rep(names(u), elementNROWS(u))
               u <- unlist(u)
               if(length(u)){
                   u$tx_name <- tids
                   names(u) <- make.names(names(u), 
                                          unique=TRUE)
               }
               u
           },
           threeUTR={
               u <- threeUTRsByTranscript(ranges,
                                          use.name=TRUE)
               tids <- rep(names(u), elementNROWS(u))
               u <- unlist(u)
               if(length(u)){
                   u$tx_name <- tids
                   names(u) <- make.names(names(u), 
                                          unique=TRUE)
               }
               u
           },
           microRNA={
               m <- microRNAs(ranges)
               if(length(m)){
                   names(m) <- m$mirna_id
                   m$mirna_id <- NULL
               }
               m
           },
           tRNA=tRNAs(ranges)
    )
}

#' EnsDb object to GRanges
#' 
#' convert EnsDb object to GRanges
#' @param ranges an EnsDb object
#' @param feature feature type, could be disjointExons, gene, exon and 
#' transcript
#' @importFrom GenomicFeatures exonicParts
#' @importFrom GenomeInfoDb `seqlevelsStyle<-`
EnsDb2GR <- function(ranges, feature){
    gr <- 
        switch(feature,
               disjointExons={
                   e <- exonicParts(ranges, linked.to.single.gene.only=TRUE)
                   l <- length(e)
                   names(e) <- make.names(
                       formatC(seq_len(l), 
                               width=nchar(as.character(l)),
                               flag="0"))
                   e
               },
               gene={
                   g <- genes(ranges, columns=c("gene_id",
                                                "gene_name"))
                   names(g) <- g$gene_id
                   g$gene_id <- NULL
                   g
               },
               exon={
                   e <- exons(ranges, 
                              columns=c("exon_id", 
                                        "tx_id", 
                                        "gene_id",
                                        "gene_name"))
                   if(length(e)){
                       names(e) <- make.names(names(e), 
                                              unique=TRUE,
                                              allow_=TRUE)
                   }
                   e
               },
               transcript={
                   t <- transcripts(ranges,
                                    columns=c("tx_id",
                                              "gene_id",
                                              "gene_name"))
                   if(length(t)){
                       names(t) <- make.names(names(t), 
                                              unique=TRUE,
                                              allow_=TRUE)
                   }
                   t
               }
        )
    #seqlevelsStyle(gr) <- "UCSC"
    gr <- formatSeqnames(gr, GRanges("chr1", IRanges(1, 2)))
    return(gr)
}


#' @importFrom stats fisher.test
removeAncestor <- function(goenrichments, onto, cutoffPvalue){
  stopifnot(colnames(goenrichments)[1] %in% c("go.id")) ## confirm the result is from getEnrichedGO
  stopifnot(onto %in% c("BP", "MF", "CC"))
  if(nrow(goenrichments)<2){
    return(goenrichments)
  }
  offsprings <- mget(as.character(goenrichments$go.id), 
                     get(paste0("GO", onto, "CHILDREN")),
                     ifnotfound = NA)
  offsprings <- lapply(offsprings, function(.ele){
    .ele <- .ele[!is.na(.ele)]
    .ele[.ele %in% as.character(goenrichments$go.id)]
  })
  keep <- mapply(function(.ele, offspring){
    if(length(offspring)<1){
      return(TRUE)
    }
    all(sapply(offspring, function(.e){
      cnt <- goenrichments[goenrichments$go.id %in% c(.ele, .e), 
                           c("count.InDataset", "count.InGenome")]
      cnt[, 2] <- cnt[, 2] - cnt[, 1]
      fisher.test(cnt, alternative = "less")$p.value < cutoffPvalue
    }))
  }, names(offsprings), offsprings)
  goenrichments[keep, , drop=FALSE]
}

getGOLevel <- function(goid, onto, level=0){
  if(any(goid=="all")){
    return(level)
  }
  parent <- mget(goid, get(paste0("GO", onto, "PARENTS")))
  parent <- unique(unlist(parent))
  level <- level + 1
  if(any(parent=="all")){
    return(level)
  }else{
    return(getGOLevel(parent, onto, level))
  }
}

filterByLevel <- function(goenrichments, onto, level=4){
  if(level<2){
    warning("keepByLevel must be a number lager than 1.
            Not used parameter keepByLevel")
    return(goenrichments)
  }
  stopifnot(colnames(goenrichments)[1] %in% c("go.id")) ## confirm the result is from getEnrichedGO
  stopifnot(onto %in% c("BP", "MF", "CC"))
  levels <- sapply(as.character(goenrichments$go.id), getGOLevel, onto=onto)
  goenrichments[levels <= level, , drop=FALSE]
}

swapList <- function(x){
  stopifnot(is.list(x))
  null <- sapply(x, function(.ele){
    stopifnot(is.list(.ele))
  })
  levelsA <- names(x)
  levelsB <- unique(unlist(sapply(x, names, simplify = FALSE)))
  y <- as.list(levelsB)
  names(y) <- levelsB
  for(.lB in levelsB){
    y[[.lB]] <- list()
  }
  for(.lA in levelsA){
    for(.lB in names(x[[.lA]])){
      y[[.lB]][[.lA]] <- x[[.lA]][[.lB]]
    }
  }
  y
}


filterByOverlaps <- function(x, ranges, ignore.strand=FALSE, 
                             minoverlap=1L, ...){
  y <- disjoin(c(x, ranges), ignore.strand=ignore.strand)
  ranges <- subsetByOverlaps(y, ranges, ignore.strand=ignore.strand)
  x <- subsetByOverlaps(y, x, ignore.strand=ignore.strand)
  subsetByOverlaps(x, ranges = ranges, invert = TRUE, 
                   ignore.strand=ignore.strand,
                   minoverlap = minoverlap,
                   ...)
}
