## Required libraries
stopifnot(packageVersion('recount.bwtool') >= '0.99.15')
library('recount.bwtool')
library('recount')
library('BiocParallel')
library('devtools')
library('getopt')

## Specify parameters
spec <- matrix(c(
    'projectid', 'p', 1, 'integer', 'A number between 1 and 2036. 2035 is GTEx and 2036 is TCGA',
    'regions', 'r', 1, 'character', 'Path to a file that has a GRanges object',
    'sumsdir', 's', 1, 'character', 'Path to the output directory for the bwtool sum files',
    'cores', 'c', 1, 'integer', 'Number of cores to use. That is, how many bigWig files to process simultaneously',
    'commands', 'o', 1, 'logical', 'Whether to create just the commands',
    'bed', 'b', 2, 'character', 'Path to a bed file (optional)',
	'help' , 'h', 0, 'logical', 'Display help'
), byrow=TRUE, ncol=5)
opt <- getopt(spec)

## if help was asked for print a friendly message
## and exit with a non-zero error code
if (!is.null(opt$help)) {
	cat(getopt(spec, usage=TRUE))
	q(status=1)
}

if(FALSE) {
    ## For testing
    opt <- list(projectid = 2036, regions = '/dcl01/lieber/ajaffe/lab/insp/IGH/IGH.Rdata', sumsdir = '/users/lcollado/rb-test', cores = 1, bed = '/dcl01/lieber/ajaffe/lab/insp/IGH/sumsIGH/recount.bwtool-2017-02-22.bed', commands = TRUE)
}

## Load the custom url table and project names
projects <- unique(recount_url$project[grep('.bw$', recount_url$file_name)])
stopifnot(opt$projectid >=1 & opt$projectid <= length(projects))
project <- projects[opt$projectid]

## Load the regions
reg_load <- function(regpath) {
    regname <- load(regpath)
    get(regname)
}
regions <- reg_load(opt$regions)
stopifnot(is(regions, 'GRanges'))

## Create the sums directory
dir.create(opt$sumsdir, recursive = TRUE, showWarnings = FALSE)

if(opt$cores == 1) {
    bp <- SerialParam()
} else {
    bp <- MulticoreParam(cores = opt$cores, outfile = Sys.getenv('SGE_STDERR_PATH'))
}

if(FALSE) {
    ## For testing
    bwtool = '/dcl01/leek/data/bwtool/bwtool-1.0/bwtool'
    bpparam = bp
    outdir = NULL
    verbose = TRUE
    sumsdir = opt$sumsdir
    bed = opt$bed
    commands_only = opt$commands
}

## Obtain rse file for the given project
rse <- coverage_matrix_bwtool(project = project,
    regions = regions, sumsdir = opt$sumsdir, bed = opt$bed,
    bpparam = bp, commands_only = opt$commands)
    
if(!opt$commands) save(rse, file = paste0('rse_', project, '.Rdata'))

## Reproducibility information
print('Reproducibility information:')
Sys.time()
proc.time()
options(width = 120)
session_info()
