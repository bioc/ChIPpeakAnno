% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/annotatePeakInBatch.R
\name{annotatePeakInBatch}
\alias{annotatePeakInBatch}
\title{Obtain the distance to the nearest TSS, miRNA, and/or exon for a list of 
peaks}
\usage{
annotatePeakInBatch(
  myPeakList,
  mart,
  featureType = c("TSS", "miRNA", "Exon"),
  AnnotationData,
  output = c("nearestLocation", "overlapping", "both", "shortestDistance", "inside",
    "upstream&inside", "inside&downstream", "upstream", "downstream",
    "upstreamORdownstream", "nearestBiDirectionalPromoters"),
  multiple = c(TRUE, FALSE),
  maxgap = -1L,
  PeakLocForDistance = c("start", "middle", "end", "endMinusStart"),
  FeatureLocForDistance = c("TSS", "middle", "start", "end", "geneEnd"),
  select = c("all", "first", "last", "arbitrary"),
  ignore.strand = TRUE,
  bindingRegion = NULL,
  ...
)
}
\arguments{
\item{myPeakList}{A \link[GenomicRanges:GRanges-class]{GRanges} object}

\item{mart}{A mart object, used if AnnotationData is not supplied, see
useMart of bioMaRt package for details}

\item{featureType}{A charcter vector used with mart argument if
AnnotationData is not supplied; choose from "TSS", "miRNA" or "Exon"}

\item{AnnotationData}{A \link[GenomicRanges:GRanges-class]{GRanges} or
\link{annoGR} object. It can be obtained from the function getAnnotation or
customized annotation of class GRanges containing additional variable:
strand (1 or + for plus strand and -1 or - for minus strand). Pre-compliled
annotations, such as TSS.human.NCBI36, TSS.mouse.NCBIM37, TSS.rat.RGSC3.4
and TSS.zebrafish.Zv8, are provided by this package (attach them with data()
function). Another method to provide annotation data is to obtain through
biomaRt in real time by using the mart and featureType option}

\item{output}{\describe{ 
\item{nearestLocation (default)}{will output the nearest features calculated 
as PeakLoc - FeatureLocForDistance; when selected, the output can consist of 
both "strictly nearest features (non-overlapping)" and "overlapping features"
as long as they are the nearest}
\item{overlapping}{will output overlapping features with maximum gap
specified as maxgap between peak range and feature range; it is possible for 
a peak to be annotated with zero ("NA" will be returned) or multiple 
overlapping features if exist}
\item{both}{will output all the nearest features as well as any features
that overlap with the peak that is not the nearest}
\item{shortestDistance}{will output the features with the shortest distance;
the "shortest distance" is determined from either ends of the feature to 
either ends of the peak} 
\item{upstream&inside}{will output all upstream and overlapping features with 
maximum gap} 
\item{inside&downstream}{will output all downstream and overlapping features 
with maximum gap}
\item{upstream}{will output all upstream features with maximum gap} 
\item{downstream}{will output all downstream features with maximum gap} 
\item{upstreamORdownstream}{will output all upstream features with maximum 
gap or downstream with maximum gap} 
\item{nearestBiDirectionalPromoters}{will use \link{annoPeaks} to
annotate peaks. Nearest promoters from both direction of the peaks (strand
is considered). It will report bidirectional promoters if there are
promoters in both directions in the given region (defined by bindingRegion).
Otherwise, it will report the closest promoter in one direction.} }}

\item{multiple}{Not applicable when output is nearest. TRUE: output multiple
overlapping features for each peak. FALSE: output at most one overlapping
feature for each peak. This parameter is kept for backward compatibility,
please use select.}

\item{maxgap}{The maximum \emph{gap} that is allowed between 2 ranges for
the ranges to be considered as overlapping. The \emph{gap} between 2 ranges
is the number of positions that separate them. The \emph{gap} between 2
adjacent ranges is 0. By convention when one range has its start or end
strictly inside the other (i.e. non-disjoint ranges), the \emph{gap} is
considered to be -1.}

\item{PeakLocForDistance}{Specify the location of peak for calculating
distance,i.e., middle means using middle of the peak to calculate distance
to feature, start means using start of the peak to calculate the distance to
feature, endMinusStart means using the end of the peak to calculate the 
distance to features on plus strand and the start of the peak to calculate 
the distance to features on minus strand. To be compatible with previous 
version, by default using start}

\item{FeatureLocForDistance}{Specify the location of feature for calculating
distance,i.e., middle means using middle of the feature to calculate
distance of peak to feature, start means using start of the feature to
calculate the distance to feature, TSS means using start of feature when
feature is on plus strand and using end of feature when feature is on minus
strand, geneEnd means using end of feature when feature is on plus strand
and using start of feature when feature is on minus strand. To be compatible
with previous version, by default using TSS}

\item{select}{"all" may return multiple overlapping peaks, "first" will
return the first overlapping peak, "last" will return the last overlapping
peak and "arbitrary" will return one of the overlapping peaks.}

\item{ignore.strand}{When set to TRUE, the strand information is ignored in
the annotation. Unless you have stranded peaks and you are interested in 
annotating peaks to the features in the same strand only, you should just 
use the default setting ignore.strand = TRUE.}

\item{bindingRegion}{Annotation range used for \link{annoPeaks}, which is a
vector with two integer values, default to c (-5000, 5000). The first one
must be no bigger than 0. And the sec ond one must be no less than 1. Once
bindingRegion is defined, annotation will based on \link{annoPeaks}. Here is
how to use it together with the parameter output and FeatureLocForDistance.
\itemize{ \item To obtain peaks with nearest bi-directional promoters within
5kb upstream and 3kb downstream of TSS, set output =
"nearestBiDirectionalPromoters" and bindingRegion = c(-5000, 3000) \item To
obtain peaks within 5kb upstream and up to 3kb downstream of TSS within the
gene body, set output="overlapping", FeatureLocForDistance="TSS" and
bindingRegion = c(-5000, 3000) \item To obtain peaks up to 5kb upstream
within the gene body and 3kb downstream of gene/Exon End, set
output="overlapping", FeatureLocForDistance="geneEnd" and bindingRegion =
c(-5000, 3000) \item To obtain peaks from 5kb upstream to 3kb downstream of
genes/Exons, set output="overlapping", bindingType = "fullRange" and
bindingRegion = c(-5000, 3000) } For details, see \link{annoPeaks}.}

\item{...}{Parameters could be passed to \link{annoPeaks}}
}
\value{
An object of \link[GenomicRanges:GRanges-class]{GRanges} with slot
start holding the start position of the peak, slot end holding the end
position of the peak, slot space holding the chromosome location where the
peak is located, slot rownames holding the id of the peak. In addition, the
following variables are included.  \item{list("feature")}{id of the feature
such as ensembl gene ID} \item{list("insideFeature")}{upstream: peak resides
upstream of the feature; downstream: peak resides downstream of the feature;
inside: peak resides inside the feature; overlapStart: peak overlaps with
the start of the feature; overlapEnd: peak overlaps with the end of the
feature; includeFeature: peak include the feature entirely}
\item{list("distancetoFeature")}{distance to the nearest feature such as
transcription start site.  By default, the distance is calculated as the
distance between the start of the binding site and the TSS that is the gene
start for genes located on the forward strand and the gene end for genes
located on the reverse strand. The user can specify the location of peak and
location of feature for calculating this}
\item{list("start_position")}{start position of the feature such as gene}
\item{list("end_position")}{end position of the feature such as the gene}
\item{list("strand")}{1 or + for positive strand and -1 or - for negative
strand where the feature is located} \item{list("shortestDistance")}{The
shortest distance from either end of peak to either end the feature.  }
\item{list("fromOverlappingOrNearest")}{Relevant only when output is set to 
"both". If "nearestLocation": indicates this feature's start (feature's end 
for features from minus strand) is the closest to the peak start ("strictly 
nearest" or "nearest overlapping"); if "Overlapping": indicates this feature 
overlaps with this peak although it is not the nearest (non-nearest 
overlapping) }
}
\description{
Obtain the distance to the nearest TSS, miRNA, exon et al for a list of peak 
locations leveraging IRanges and biomaRt package
}
\examples{


    ## example 1: annotate myPeakList by TxDb or EnsDb.
    data(myPeakList)
    library(ensembldb)
    library(EnsDb.Hsapiens.v75)
    annoData <- annoGR(EnsDb.Hsapiens.v75)
    annotatePeak = annotatePeakInBatch(myPeakList[1:6], AnnotationData=annoData)
    annotatePeak
    
    ## example 2: annotate myPeakList (GRanges) 
    ## with TSS.human.NCBI36 (Granges)
    data(TSS.human.NCBI36)
    annotatedPeak = annotatePeakInBatch(myPeakList[1:6], 
                                        AnnotationData=TSS.human.NCBI36)
    annotatedPeak
    
    ## example 3: you have a list of transcription factor biding sites from 
    ## literature and are interested in determining the extent of the overlap 
    ## to the list of peaks from your experiment. Prior calling the function 
    ## annotatePeakInBatch, need to represent both dataset as GRanges 
    ## where start is the start of the binding site, end is the end of the 
    ## binding site, names is the name of the binding site, space and strand 
    ## are the chromosome name and strand where the binding site is located.
    
    myexp <- GRanges(seqnames=c(6,6,6,6,5,4,4), 
                     IRanges(start=c(1543200,1557200,1563000,1569800,
                                     167889600,100,1000),
                             end=c(1555199,1560599,1565199,1573799,
                                   167893599,200,1200),
                             names=c("p1","p2","p3","p4","p5","p6", "p7")), 
                     strand="+")
    literature <- GRanges(seqnames=c(6,6,6,6,5,4,4), 
                          IRanges(start=c(1549800,1554400,1565000,1569400,
                                          167888600,120,800),
                                  end=c(1550599,1560799,1565399,1571199,
                                        167888999,140,1400),
                                  names=c("f1","f2","f3","f4","f5","f6","f7")),
                          strand=rep(c("+", "-"), c(5, 2)))
    annotatedPeak1 <- annotatePeakInBatch(myexp, 
                                          AnnotationData=literature)
    pie(table(annotatedPeak1$insideFeature))
    annotatedPeak1
    ### use toGRanges or rtracklayer::import to convert BED or GFF format
    ###  to GRanges before calling annotatePeakInBatch
    test.bed <- data.frame(space=c("4", "6"), 
                           start=c("100", "1000"),
                           end=c("200", "1100"), 
                           name=c("peak1", "peak2"))
    test.GR = toGRanges(test.bed)
    annotatePeakInBatch(test.GR, AnnotationData = literature)
 
 library(testthat)
  peak <- GRanges(seqnames = "chr1", 
                  IRanges(start = 24736757, end=24737528,
                          names = "testPeak"))
  data(TSS.human.GRCh37)
  TSS.human.GRCh37[names(TSS.human.GRCh37)== "ENSG00000001461"]
  # GRanges object with 1 range and 1 metadata column:
  # seqnames            ranges strand |            description
  #<Rle>         <IRanges>  <Rle> |            <character>
  # ENSG00000001461        1 24742285-24799466      + | NIPA-like domain con..
  peak
  #GRanges object with 1 range and 0 metadata columns:
  #   seqnames            ranges strand
  #<Rle>         <IRanges>  <Rle>
  #  testPeak     chr1 24736757-24737528      *
  TSS.human.GRCh37[names(TSS.human.GRCh37)== "ENSG00000001460"]
  #GRanges object with 1 range and 1 metadata column:
  #   seqnames            ranges strand |            description
  #<Rle>         <IRanges>  <Rle> |            <character>
  #   ENSG00000001460        1 24683490-24743424      - | UPF0490 protein C1or..
  ap <- annotatePeakInBatch(peak, Annotation=TSS.human.GRCh37, 
                            PeakLocForDistance = "start")
  stopifnot(ap$feature=="ENSG00000001461")
  ap <- annotatePeakInBatch(peak, Annotation=TSS.human.GRCh37,
                            PeakLocForDistance = "end")
  stopifnot(ap$feature=="ENSG00000001461")
  ap <- annotatePeakInBatch(peak, Annotation=TSS.human.GRCh37,
                            PeakLocForDistance = "middle")
  stopifnot(ap$feature=="ENSG00000001461")
  ap <- annotatePeakInBatch(peak, Annotation=TSS.human.GRCh37,
                            PeakLocForDistance = "endMinusStart")
  stopifnot(ap$feature=="ENSG00000001461")
  ## Let's calculate the distances between the peak and the TSS of the genes
  ## in the annotation file used for annotating the peaks.
  ## Please note that we need to compute the distance using the annotation
  ## file TSS.human.GRCh37.
  ## If you would like to use  TxDb.Hsapiens.UCSC.hg19.knownGene, 
  ## then you will need to annotate the peaks
  ## using TxDb.Hsapiens.UCSC.hg19.knownGene as well.
  ### using start
  start(peak) -start(TSS.human.GRCh37[names(TSS.human.GRCh37)== 
                                      "ENSG00000001461"]) #picked
  #[1] -5528
  start(peak) -end(TSS.human.GRCh37[names(TSS.human.GRCh37)==
                                   "ENSG00000001460"])
  #[1] -6667
  #### using middle
  (start(peak) + end(peak))/2 -
      start(TSS.human.GRCh37[names(TSS.human.GRCh37)== "ENSG00000001461"])
  #[1] -5142.5
  (start(peak) + end(peak))/2 -
      end(TSS.human.GRCh37[names(TSS.human.GRCh37)== "ENSG00000001460"])
  # [1] 49480566
  end(peak) -start(TSS.human.GRCh37[names(TSS.human.GRCh37)==
                                   "ENSG00000001461"]) #picked
  # [1] -4757
  end(peak) -end(TSS.human.GRCh37[names(TSS.human.GRCh37)==
                                 "ENSG00000001460"])
  # [1] -5896
  #### using endMinusStart
  end(peak) - start(TSS.human.GRCh37[names(TSS.human.GRCh37)==
                                    "ENSG00000001461"]) ## picked
  # [1] -4575
  start(peak) -end(TSS.human.GRCh37[names(TSS.human.GRCh37)==
                                    "ENSG00000001460"])
  #[1] -6667
  ###### using txdb object to annotate the peaks
  library(org.Hs.eg.db)
  select(org.Hs.eg.db, key="STPG1", keytype="SYMBOL",
         columns=c("ENSEMBL", "ENTREZID", "SYMBOL"))
  #  SYMBOL         ENSEMBL ENTREZID
  #  STPG1 ENSG00000001460    90529
  select(org.Hs.eg.db, key= "ENSG00000001461", keytype="ENSEMBL",
         columns=c("ENSEMBL", "ENTREZID", "SYMBOL"))
  #ENSEMBL ENTREZID SYMBOL
  # ENSG00000001461    57185 NIPAL3
  require(TxDb.Hsapiens.UCSC.hg19.knownGene)
  txdb.ann <- genes(TxDb.Hsapiens.UCSC.hg19.knownGene)
  STPG1 <- select(org.Hs.eg.db, key="STPG1", keytype="SYMBOL",
                  columns=c( "SYMBOL", "ENSEMBL", "ENTREZID"))[1,3]
  NIPAL3 <- select(org.Hs.eg.db, key="NIPAL3", keytype="SYMBOL",
                   columns=c( "SYMBOL", "ENSEMBL", "ENTREZID"))[1,3]
  ap <- annotatePeakInBatch(peak, Annotation=txdb.ann,
                            PeakLocForDistance = "start")
  expect_equal(ap$feature, STPG1)
  ap <- annotatePeakInBatch(peak, Annotation=txdb.ann,
                            PeakLocForDistance = "end")
  expect_equal(ap$feature, STPG1)
  ap <- annotatePeakInBatch(peak, Annotation=txdb.ann,
                            PeakLocForDistance = "middle")
  expect_equal(ap$feature, STPG1)
  ap <- annotatePeakInBatch(peak, Annotation=txdb.ann,
                            PeakLocForDistance = "endMinusStart")
  expect_equal(ap$feature, NIPAL3)
  txdb.ann[NIPAL3]
  txdb.ann[txdb.ann$gene_id == NIPAL3]
  #  GRanges object with 1 range and 1 metadata column:
  #    seqnames            ranges strand |     gene_id
  #  <Rle>         <IRanges>  <Rle> | <character>
  #   57185     chr1 24742245-24799473      + |       57185
  #-------
  txdb.ann[txdb.ann$gene_id == STPG1]
  #   GRanges object with 1 range and 1 metadata column:
  #     seqnames            ranges strand |     gene_id
  #  <Rle>         <IRanges>  <Rle> | <character>
  #     90529     chr1 24683489-24741587      - |       90529

}
\references{
1. Zhu L.J. et al. (2010) ChIPpeakAnno: a Bioconductor package
to annotate ChIP-seq and ChIP-chip data. BMC Bioinformatics 2010,
11:237doi:10.1186/1471-2105-11-237

2. Zhu L (2013). "Integrative analysis of ChIP-chip and ChIP-seq dataset."
In Lee T and Luk ACS (eds.), Tilling Arrays, volume 1067, chapter 4, pp.
-19.  Humana Press. http://dx.doi.org/10.1007/978-1-62703-607-8_8
}
\seealso{
\link{getAnnotation}, \link{findOverlappingPeaks},
\link{makeVennDiagram}, \link{addGeneIDs}, \link{peaksNearBDP},
\link{summarizePatternInPeaks}, \link{annoGR}, \link{annoPeaks}
}
\author{
Lihua Julie Zhu, Jianhong Ou
}
\keyword{misc}
