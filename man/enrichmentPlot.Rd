% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/enrichmentPlot.R
\name{enrichmentPlot}
\alias{enrichmentPlot}
\title{plot enrichment results}
\usage{
enrichmentPlot(
  res,
  n = 20,
  strlength = Inf,
  style = c("v", "h"),
  label_wrap = 40,
  label_substring_to_remove = NULL,
  orderBy = c("pvalue", "termId", "none")
)
}
\arguments{
\item{res}{output of \link{getEnrichedGO}, \link{getEnrichedPATH}.}

\item{n}{number of terms to be plot.}

\item{strlength}{shorten the description of term by the number of char.}

\item{style}{plot vertically or horizontally}

\item{label_wrap}{soft wrap the labels (i.e. descriptions of the GO or PATHWAY terms), default to 40 characters.}

\item{label_substring_to_remove}{remove common substring from label, 
default to NULL. Special characters must be escaped. E.g. if you would like 
to remove "Homo sapiens (human)" from labels, you must use "Homo sapiens \\\(
human\\\)".}

\item{orderBy}{order the data by pvalue, termId or none.}
}
\value{
an object of ggplot
}
\description{
Plot the GO/KEGG/reactome enrichment results
}
\examples{
data(enrichedGO)
enrichmentPlot(enrichedGO)
if (interactive()||Sys.getenv("USER")=="jianhongou") {
     
     library(org.Hs.eg.db)
     library(GO.db)
     bed <- system.file("extdata", "MACS_output.bed", package="ChIPpeakAnno")
     gr1 <- toGRanges(bed, format="BED", header=FALSE) 
     gff <- system.file("extdata", "GFF_peaks.gff", package="ChIPpeakAnno")
     gr2 <- toGRanges(gff, format="GFF", header=FALSE, skip=3)
     library(EnsDb.Hsapiens.v75) ##(hg19)
     annoData <- toGRanges(EnsDb.Hsapiens.v75)
     gr1.anno <- annoPeaks(gr1, annoData)
     gr2.anno <- annoPeaks(gr2, annoData)
     over <- lapply(GRangesList(gr1=gr1.anno, gr2=gr2.anno), 
                    getEnrichedGO, orgAnn="org.Hs.eg.db",
                    maxP=.05, minGOterm=10, condense=TRUE)
     enrichmentPlot(over$gr1)
     enrichmentPlot(over$gr2, style = "h")
 }
}
\author{
Jianhong Ou, Kai Hu
}
