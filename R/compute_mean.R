#' Given a set of bigwig files, create a scaled mean BigWig file.
#'
#' Given a set of BigWig files, create a scaled mean BigWig file using the
#' area under coverage (AUC) to scale the BigWig files. The AUC will be
#' calculated using wiggletools if necessary. This function requires 
#' the external dependencies wiggletools and wigToBigWig to work.
#'
#' @param bws A named vector with the paths to the bigWig files. The names
#' are used as sample ids.
#' @param outfile The name of the mean bigwig file to create.
#' @param aucs A vector of equal length to \code{bws} with the AUCs for each
#' BigWig file. If absent, this infomration will be calculated using
#' wiggletools.
#' @param chr_sizes A single character vector with the path to the chr
#' sizes file. This depends on the reference genome used for creating the
#' BigWig files.
#' @param auc_scale The value to which the BigWig AUCs will be scaled to. By
#' default this corresponds to 40 million 100 bp reads.
#' @param wiggletools Path to wiggletools. At JHPCE note that you'll have to
#' use \code{module load wiggletools/default} before opening R.
#' @param wigToBigWig Path to wigToBigWig. At JHPCE note that you'll have to use
#' \code{module load ucsctools} before opening R.
#' @param tempdir Path to a temporary directory to use for saving the
#' intermediate files. You might have to specify one yourself when processing
#' many BigWig files.
#' 
#'
#' @return The path to the mean Wig and BigWig files as well as scripts that 
#' were created in the process.
#'
#' @details Based on parts of 
#' https://github.com/leekgroup/recount-website/blob/master/recount-prep/prep_merge.R
#'
#' @author Leonardo Collado-Torres
#' @export
#'
#' @importFrom Hmisc cut2
#'
#'
#' @seealso \link[recount.bwtool]{coverage_matrix_bwtool}
#'
#' @examples
#'
#' if(.Platform$OS.type != 'windows') {
#' ## Disable the example for now. I'd have to figure out how to install
#' ## bwtool on travis
#' if(FALSE) {
#'     ## Works at JHPCE. Load the appropriate modules before opening R.
#'     # module load wiggletools/default
#'     # module load ucsctools
#'     # R
#'
#'     library('recount')
#'     library('recount.bwtool')
#' bws <- recount_url$path[match(colData(rse_gene_SRP009615)$bigwig_file, recount_url$file_name)]
#'     compute_mean(bws[1:2], chr_sizes = '/dcl01/leek/data/gtex_work/runs/gtex/hg38.sizes', tempdir = 'testBW')
#' }
#' }
#'



compute_mean <- function(bws, outfile = 'mean', aucs = NULL, 
    chr_sizes = '/dcl01/lieber/ajaffe/Emily/RNAseq-pipeline/Annotation/hg38.chrom.sizes.gencode',
    auc_scale = 40e6 * 100, wiggletools = 'wiggletools',
    wigToBigWig = 'wigToBigWig', tempdir = getwd()) {
        
    stopifnot(all(file.exists(bws)))
    stopifnot(file.exists(chr_sizes))
    if(!dir.exists(tempdir)) {
        dir.create(tempdir, showWarnings = FALSE)
    }    
    if(!is.null(aucs)) {
        stopifnot(length(bws) == length(aucs))
    } else {
        ## Calculate AUCs
        aucs <- sapply(seq_len(length(bws)), function(i) {
            auc_file <- file.path(tempdir, paste0('bw_sample', i, '.auc'))
            system(paste(wiggletools, 'AUC', auc_file, bws[i]))
            as.numeric(readLines(auc_file))
        })
    }

    outbw <- paste0(outfile, '.bw')
    outwig <- paste0(outfile, '.wig')
    metadata <- data.frame(bw = bws, auc = aucs)
    
    scaleWig <- function(m) {
        paste(paste('scale', round(auc_scale / m$auc, digits = 17), m$bw),
            collapse = ' ')
    }
    
    runCmd <- function(cmd, i = NULL) {
        if(is.null(i)) {
            shell_name <- paste0('.createWig_', Sys.Date(), '.sh')
        } else {
            shell_name <- paste0('.createWig_', Sys.Date(), '_part', i, '.sh')
        }
        message(paste(Sys.time(), 'command used:', cmd))
        cat(cmd, file = shell_name)
        system(paste('sh', shell_name))
    }
    ## Calculate mean bigwig
    if(nrow(metadata) < 100) {
        ## Scale commands
        cmd <- scaleWig(metadata)
        ## Calculate mean wig file
        message(paste(Sys.time(), 'creating file', outwig))
        cmd <- paste(wiggletools, 'write', outwig, 'mean', cmd)
        system.time( runCmd(cmd) )
    } else {
        ## Define subsets to work on
        sets <- cut2(seq_len(nrow(metadata)), m = 50)
        meta <- split(metadata, sets)
        names(meta) <- seq_len(length(meta))

        ## Calculate sums per subsets
        system.time( tmpfiles <- mapply(function(m, i) {
            cmd <- scaleWig(m)
       
            tmpwig <- file.path(tempdir, paste0('sum_part', i, '.wig'))
            message(paste(Sys.time(), 'creating file', tmpwig))
            cmd <- paste(wiggletools, 'write', tmpwig, 'sum', cmd)
            runCmd(cmd, i)
            return(tmpwig)
        }, meta, names(meta)) )

        ## Calculate final mean
        cmd <- paste(wiggletools, 'write', outwig, 'scale',
            1/nrow(metadata), 'sum', paste(tmpfiles, collapse = ' '))
        system.time( runCmd(cmd) )
    
        ## Clean up
        sapply(tmpfiles, unlink)
    }

    ## Transform to bigwig file
    message(paste(Sys.time(), 'creating file', outbw))
    cmd2 <- paste(wigToBigWig, outwig, chr_sizes, outbw)
    system.time( system(cmd2) )
    
    if(file.exists(outwig)) {
        message(paste(Sys.time(), 'mean BigWig was successfully created at', outbw))
    } else {
        message(paste(Sys.time(), 'mean BigWig file creation failed'))
    }
    
    filesCreated <- c(outbw, outwig,
        dir(pattern = paste0('.createWig_', Sys.Date()), all.files = TRUE),
        dir(tempdir, pattern = '.auc$', full.names = TRUE))
    return(filesCreated)
}
