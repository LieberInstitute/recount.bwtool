% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/coverage_bwtool.R
\name{coverage_bwtool}
\alias{coverage_bwtool}
\title{Given a set of regions and bigwig files, compute the coverage matrix for
using \code{bwtool} and build a
\link[SummarizedExperiment]{RangedSummarizedExperiment-class} object.}
\usage{
coverage_bwtool(bws, regions, strand = "*", pheno = NULL,
  bwtool = "/dcl01/leek/data/bwtool/bwtool-1.0/bwtool", bpparam = NULL,
  verbose = TRUE, sumsdir = tempdir(), commands_only = FALSE,
  overwrite = FALSE, stranded_sumsdir = TRUE)
}
\arguments{
\item{bws}{A named vector with the paths to the bigWig files. The names
are used as sample ids.}

\item{regions}{A \link[GenomicRanges]{GRanges-class} object with regions
for which to calculate the coverage matrix.}

\item{strand}{Either *, + or -. If set to * (default) then all regions are
used. Otherwise the matrix is subset to the regions of the corresponding
strand. The users should supply the correct corresponding list of bigWig
files in \code{bws}.}

\item{pheno}{\code{NULL} by default. Specify the data.frame with the same
length as \code{bws} to be used in the resulting RSE object.}

\item{bwtool}{The path to \code{bwtool}. Uses as the default the
location at JHPCE.}

\item{bpparam}{A \link[BiocParallel]{BiocParallelParam-class} instance which
will be used to calculate the coverage matrix in parallel. By default, 
\link[BiocParallel]{SerialParam-class} will be used.}

\item{verbose}{If \code{TRUE} basic status updates will be printed along the 
way.}

\item{sumsdir}{The path to an existing directory where the \code{bwtool}
sum tsv files will be saved. We recommend setting this to a value beyond
the default one.}

\item{commands_only}{If \code{TRUE} the bwtool commands will be saved in a
file called coverage_bwtool_strandSTRAND.txt and exit without running
\code{bwtool}. This is useful if you have a very large regions set and want
to run the commands in an array job. Then run
\code{coverage_bwtool(commands_only = FALSE)} to create the RSE
object(s).}

\item{overwrite}{Logical, whether to overwrite output files.}

\item{stranded_sumsdir}{Logical, whether to automatically add the strand
to \code{sumsdir}, to avoid overwriting files from different strands.}
}
\value{
A \link[SummarizedExperiment]{RangedSummarizedExperiment-class}
object with the counts stored in the assays slot.
}
\description{
Given a set of regions and bigwig files, compute the coverage matrix for
using \code{bwtool} and build a
\link[SummarizedExperiment]{RangedSummarizedExperiment-class} object.
}
\details{
Based on \link{coverage_matrix_bwtool}, but made more general for
data outside recount2.
}
\examples{

if(.Platform$OS.type != 'windows') {
## Disable the example for now. I'd have to figure out how to install
## bwtool on travis
if(FALSE) {
    ## Reading BigWig files is not supported by rtracklayer on Windows
    ## (only needed for defining the regions in this example)
    
    ## TODO
}
}

}
\seealso{
\link[recount.bwtool]{coverage_matrix_bwtool}
}
\author{
Leonardo Collado-Torres
}
