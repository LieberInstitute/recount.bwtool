#' Given a set of regions for a chromosome, compute the coverage matrix for a
#' given SRA study using \code{bwtool} as a 
#' \link[SummarizedExperiment]{RangedSummarizedExperiment-class} object.
#'
#' Given a set of genomic regions as created by 
#' \link[recount]{expressed_regions}, this
#' function computes the coverage matrix using \code{bwtool}. You can
#' then scale the counts to a 40 million 100 bp reads library using
#' \link[recount]{scale_counts}.
#'
#' @param project A character vector with one SRA study id.
#' @param regions A \link[GenomicRanges]{GRanges-class} object with regions
#' for which to calculate the coverage matrix.
#' @param bwtool The path to \code{bwtool}. Uses as the default the
#' location at JHPCE.
#' @param bpparam A \link[BiocParallel]{BiocParallelParam-class} instance which
#' will be used to calculate the coverage matrix in parallel. By default, 
#' \link[BiocParallel]{SerialParam-class} will be used.
#' @param outdir The destination directory for the downloaded file(s) that were
#' previously downloaded with \link{download_study}. If the files are missing, 
#' but \code{outdir} is specified, they will get downloaded first. By default
#' \code{outdir} is set to \code{NULL} which will use the data from the web.
#' We only recommend downloading the full data if you will use it several times.
#' Note that if you are working at JHPCE or SciServer, the files will be
#' located automatically.
#' @param verbose If \code{TRUE} basic status updates will be printed along the 
#' way.
#' @param sumsdir The path to an existing directory where the \code{bwtool}
#' sum tsv files will be saved.
#' @param bed The path to the BED file for the regions. You are responsible
#' for making sure that the BED file and the regions are in the same order.
#' Could be useful for a scenario where you have a BED file and import it to
#' define \code{regions}.
#' @param url_table A custom data.frame named with the same columns as
#' \code{recount::recount_url}. If \code{NULL}, the default is 
#' \code{recount::recount_url}.
#' Note that project SRP012682 is only available at JHPCE. Use \code{local_url}
#' saved in \code{/dcl01/leek/data/recount-website/fileinfo/local_url.RData}.
#' 
#' @param ... Additional arguments passed to \link{download_study} when
#' \code{outdir} is specified but the required files are missing.
#' 
#'
#' @return A \link[SummarizedExperiment]{RangedSummarizedExperiment-class}
#' object with the counts stored in the assays slot. 
#'
#' @details When using \code{outdir = NULL} the information will be accessed
#' from the web on the fly. If you encounter internet access problems, it might
#' be best to first download the BigWig files using \link{download_study}. This
#' might be the best option if you are accessing all chromosomes for a given
#' project and/or are thinking of using different sets of \code{regions} (for
#' example, from different cutoffs applied to \link{expressed_regions}).
#' If you are working at JHPCE (and part of \code{leekgroup}) or at SciServer,
#' the files will be located automatically.
#'
#' @author Leonardo Collado-Torres
#' @export
#'
#' @importFrom utils read.table
#' @importFrom methods is
#' @import GenomicRanges RCurl BiocParallel rtracklayer recount 
#' SummarizedExperiment S4Vectors
#'
#' @seealso \link[recount]{coverage_matrix}, \link[recount]{download_study},
#' \link[derfinder]{findRegions}, \link[derfinder]{railMatrix}
#'
#' @details
#' Check also \code{system.file('extdata', 'jhpce', package = 'recount.bwtool')}
#' for some scripts that will run this function for all the projects we have
#' available at JHPCE.
#'
#' @examples
#'
#' if(.Platform$OS.type != 'windows') {
#' ## Disable the example for now. I'd have to figure out how to install
#' ## bwtool on travis
#' if(FALSE) {
#'     ## Reading BigWig files is not supported by rtracklayer on Windows
#'     ## (only needed for defining the regions in this example)
#'     ## Define expressed regions for study DRP002835, chrY
#'     regions <- expressed_regions('DRP002835', 'chrY', cutoff = 5L, 
#'         maxClusterGap = 3000L)
#'
#'     ## Now calculate the coverage matrix for this study
#'     rse <- coverage_matrix_bwtool('DRP002835', regions)
#'
#'     ## Scale counts
#'     rse_scaled <- scale_counts(rse, round = FALSE)
#' }
#' }
#'

coverage_matrix_bwtool <- function(project, regions,
    bwtool = '/dcl01/leek/data/bwtool/bwtool-1.0/bwtool',
    bpparam = NULL, outdir = NULL, verbose = TRUE, sumsdir = tempdir(),
    bed = NULL, url_table = NULL, ...) {    
    ## Check inputs
    stopifnot(is.character(project) & length(project) == 1)
    stopifnot(is(regions, 'GRanges'))
    
    ## Use table from the recount package
    if(is.null(url_table)) {
        url_table <- recount::recount_url
    } else {
        stopifnot(all(colnames(recount::recount_url) %in% colnames(url_table)))
    }
    
    ## Subset url data
    url_table <- url_table[url_table$project == project, ]
    stopifnot(nrow(url_table) > 0)
    
    ## Export regions to a BED file if necessary
    if(is.null(bed)) {
        bed <- file.path(sumsdir, paste0('recount.bwtool-', Sys.Date(), '.bed'))
    }
    
    if(!file.exists(bed)) {
        if (verbose) message(paste(Sys.time(), 'creating the BED file', bed))
        rtracklayer::export(regions, con = bed, format='BED')
        stopifnot(file.exists(bed))
    }
    
    ## BigWig index
    samples_i <- which(grepl('[.]bw$', url_table$file_name) & !grepl('mean',
        url_table$file_name))
    
    ## Are we on JHPCE? SciServer?
    jhpce <- sciserver <- FALSE
    jhpce <- all(file.exists(url_table$path))
    sciserver <- all(file.exists(gsub('http://duffel.rail.bio/recount/',
        '/home/idies/workspace/recount01/', url_table$url)))
    
    ## Load the data from JHPCE, SciServer, 'outdir' or download it
    if(jhpce) {
        sampleFiles <- url_table$path[samples_i]
        phenoFile <- url_table$path[url_table$file_name == paste0(project,
            '.tsv')]
    } else if (sciserver) {
        if(project == 'SRP012682') stop("The BigWig files for project SRP012682 are not on SciServer.")
        sampleFiles <- gsub('http://duffel.rail.bio/recount/',
            '/home/idies/workspace/recount01/', url_table$url[samples_i])
        phenoFile <- gsub('http://duffel.rail.bio/recount/',
            '/home/idies/workspace/recount01/', 
            url_table$url[url_table$file_name == paste0(project, '.tsv')])
    } else if (!is.null(outdir)) {
        ## Check if data is present, otherwise download it
        ## Check sample files
        sampleFiles <- sapply(samples_i, function(i) {
            file.path(outdir, 'bw', url_table$file_name[i])
        })
        if(any(!file.exists(sampleFiles))) {
            if(project == 'SRP012682') stop("The BigWig files for project SRP012682 are not publicly available.")
            download_study(project = project, type = 'samples', outdir = outdir,
                download = TRUE, ...)
        }
        
        ## Check phenotype data
        phenoFile <- file.path(outdir, paste0(project, '.tsv'))
        if(!file.exists(phenoFile)) {
            download_study(project = project, type = 'phenotype',
                outdir = outdir, download = TRUE, ...)
        }
    } else {
        sampleFiles <- download_study(project = project, type = 'samples',
            download = FALSE)
        phenoFile <- download_study(project = project, type = 'phenotype',
            download = FALSE)
    }
        
    ## Read pheno data
    pheno <- recount:::.read_pheno(phenoFile, project)
    
    ## Get sample names
    m <- match(url_table$file_name[samples_i], pheno$bigwig_file)
    if(project != 'TCGA') {
        names(sampleFiles) <- pheno$run[m]
    } else {
        names(sampleFiles) <- pheno$gdc_file_id[m]
    }
    
    ## Define bpparam
    if(is.null(bpparam)) bpparam <- BiocParallel::SerialParam()
    
    ## Run bwtool and load the data
    counts <- bpmapply(.run_bwtool, sampleFiles, names(sampleFiles),
        MoreArgs = list('bwtool' = bwtool, 'bed' = bed, 'sumsdir' = sumsdir,
        'verbose' = verbose), SIMPLIFY = FALSE, BPPARAM = bpparam)
    
    ## Group results from all files
    counts <- do.call(cbind, counts)
    
    ## Build a RSE object
    rse <- SummarizedExperiment(assays = list('counts' = counts),
            colData = DataFrame(pheno), rowRanges = regions)
    
    ## Finish
    return(rse)
}

.run_bwtool <- function(bigwig, sample, bwtool, bed, sumsdir, verbose) {
    if(verbose) message(paste(Sys.time(), 'processing sample', sample))
    output <- file.path(sumsdir, paste0(sample, '.sum.tsv'))
    cmd <- paste(bwtool, 'summary', bed, bigwig, "/dev/stdout -fill=0 -with-sum | cut -f1-3,10 | awk -v CONVFMT=%.17g '{print $1 \"\t\" $2 \"\t\" $3 \"\t\" $4}' >", output)
    system(cmd)
    stopifnot(file.exists(output))
    
    res <- read.table(output, header = FALSE,
        colClasses = list(NULL, NULL, NULL, 'numeric'))
    colnames(res) <- sample
    return(as.matrix(res))
}
