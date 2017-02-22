library('SummarizedExperiment')
library('Hmisc')
library('devtools')

files_load <- function(f) {
    message(paste(Sys.time(), 'loading file', f))
    load(f)
    return(rse)
}

files_main <- function() {
    message(paste(Sys.time(), 'locating files'))
    rse_files <- dir(pattern = 'rse_', full.names = TRUE)
    
    ## Exclude GTEx and TCGA if present
    if(grepl('TCGA', rse_files)) {
        rse_files <- rse_files[-grep('TCGA', rse_files)]
    }
    if(grepl('SRP012682', rse_files)) {
        rse_files <- rse_files[-grep('SRP012682', rse_files)]
    }
    
    ## Split files into groups of ~20
    rse_files_list <- split(rse_files, cut2(seq_len(length(rse_files)), m = 20))
    
    
    rse_list_file <- 'rse_list.Rdata'
    rse_list_sets_file <- 'rse_list_sets.Rdata'
    
    if(!file.exists(rse_list_sets_file)) {
        if(!file.exists(rse_list_file)) {
            message(paste(Sys.time(), 'loading individual RSE files'))
            rse_list <- lapply(rse_files_list, function(x) {
                res <- lapply(x, files_load)
                message(paste(Sys.time(), 'merging RSE objects (group)'))
                do.call(cbind, res)
            })
    
            message(paste(Sys.time(), 'saving rse_list'))
            save(rse_list, file = rse_list_file)
        } else {
            message(paste(Sys.time(),
                'loading previously computed rse_list'))
            load(rse_list_file)
        }
        
        message(paste(Sys.time(),
            'merging RSE objects by sets of groups'))
        group.sets <- cut2(seq_len(length(rse_list)), m = 5)
        rse_list_sets <- lapply(levels(group.sets), function(group) {
            do.call(cbind, rse_list[group.sets == group])
        })
        message(paste(Sys.time(), 'saving rse_list_sets'))
        save(rse_list_sets, file = rse_list_sets_file)
        rm(rle_list)
    } else {
        message(paste(Sys.time(),
            'loading previously computed rse_list_sets'))
        load(rse_list_sets_file)
    }
    
    message(paste(Sys.time(), 'merging RSE objects from sets'))
    ## Extract data from sets
    message(paste(Sys.time(), 'extracting information from sets'))
    col_data <- do.call(rbind, lapply(rse_list_sets, colData))
    row_ranges <- rowRanges(rse_list_sets[[1]])
    counts_list <- lapply(rse_list_sets, function(x) assays(x)$counts)
    rm(rse_list_sets)
    
    ## Prepare counts matrix
    message(paste(Sys.time(), 'preparing the counts matrix'))
    counts_n <- sapply(counts_list, ncol)
    counts_adj <- c(0, cumsum(counts_n[1:(length(counts_n) - 1)]))
    counts_idx <- mapply(function(n, adj) { seq_len(n) + adj}, counts_n,
        counts_adj, SIMPLIFY = FALSE)
    
    ## Initialize count matrix
    message(paste(Sys.time(), 'initializing counts matrix'))
    counts <- matrix(0, nrow = nrow(counts_list[[1]]),
        ncol = sum(counts_n), dimnames = list(rownames(counts_list[[1]]),
        unlist(lapply(counts_list, colnames))))
    
    ## Fill in matrix
    for(i in seq_len(length(counts_idx))) {
        message(paste(Sys.time(), 'filling in counts matrix with set', i))
        counts[, counts_idx[[i]]] <- counts_list[[i]]
    }
    
    message(paste(Sys.time(), 'creating final rse object'))
    rse <- SummarizedExperiment(assays = list('counts' = counts),
            rowRanges = row_ranges, colData = col_data)

    
    ## Save results
    message(paste(Sys.time(), 'saving the final rse_sra object'))
    save(rse, file = 'rse_sra.Rdata')
    return('rse.Rdata')
}

if(!file.exists('rse.Rdata')) {
    message(paste(Sys.time(), 'processing rse files'))
    files_main()
} else {
    message(paste(Sys.time(), 'rse.Rdata already exists and will not be overwritten'))
}

## Reproducibility information
print('Reproducibility information:')
Sys.time()
proc.time()
options(width = 120)
session_info()
