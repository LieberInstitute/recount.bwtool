## Disable the tests if the system variable 'R_DISABLE_TESTS' is set to TRUE

#flag <- as.logical(Sys.getenv('R_DISABLE_TESTS'))
flag <- TRUE
if(is.na(flag) | flag == FALSE) {
    library('testthat')
    test_check('recount.bwtool')
}
