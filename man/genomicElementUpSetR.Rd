% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomicElementUpSetR.R
\name{genomicElementUpSetR}
\alias{genomicElementUpSetR}
\title{Genomic Element data for upset plot}
\usage{
genomicElementUpSetR(
  peaks,
  TxDb,
  seqlev,
  ignore.strand = TRUE,
  breaks = list(distal_upstream = c(-1e+05, -10000, -1, 1), proximal_upstream = c(-10000,
    -5000, -1, 1), distal_promoter = c(-5000, -2000, -1, 1), proximal_promoter = c(-2000,
    200, -1, 0), `5'UTR` = fiveUTRsByTranscript, `3'UTR` = threeUTRsByTranscript, CDS =
    cds, exon = exons, intron = intronsByTranscript, gene_body = genes,
    immediate_downstream = c(0, 2000, 1, 1), proximal_downstream = c(2000, 5000, 1, 1),
    distal_downstream = c(5000, 1e+05, 1, 1))
)
}
\arguments{
\item{peaks}{peak list, \link[GenomicRanges:GRanges-class]{GRanges} object or
a \link[GenomicRanges:GRangesList-class]{GRangesList}.}

\item{TxDb}{an object of \code{\link[GenomicFeatures:TxDb-class]{TxDb}}}

\item{seqlev}{sequence level should be involved. 
Default is all the sequence levels in intersect of peaks and TxDb.}

\item{ignore.strand}{logical. Whether the strand of the input ranges
should be ignored or not. Default=TRUE}

\item{breaks}{list. A list for labels and sets for the genomic elements.
The element could be an S4 method for signature 'TxDb' or a numeric vector
with length of 4. The three numbers are 
c(upstream point, downstream point, promoter (-1) or downstream (1),
 remove gene body or not (1: remove, 0: keep)).}
}
\value{
list of data for plot.
}
\description{
Prepare data for upset plot for genomic element distribution
}
\details{
The data will be calculated by for each breaks. 
No precedence will be considered.
}
\examples{
if (interactive() || Sys.getenv("USER")=="jianhongou"){
  data(myPeakList)
  if(require(TxDb.Hsapiens.UCSC.hg19.knownGene)){
  seqinfo(myPeakList) <- 
  seqinfo(TxDb.Hsapiens.UCSC.hg19.knownGene)[seqlevels(myPeakList)]
  myPeakList <- GenomicRanges::trim(myPeakList)
  myPeakList <- myPeakList[width(myPeakList)>0]
  x <- genomicElementUpSetR(myPeakList, 
    TxDb.Hsapiens.UCSC.hg19.knownGene)
  library(UpSetR)
  upset(x$plotData, nsets=13, nintersects=NA)
  }
}
}
