Status: Travis CI [![Build Status](https://travis-ci.org/LieberInstitute/recount.bwtool.svg?branch=master)](https://travis-ci.org/LieberInstitute/recount.bwtool), Codecov [![codecov.io](https://codecov.io/github/LieberInstitute/recount.bwtool/coverage.svg?branch=master)](https://codecov.io/github/LieberInstitute/recount.bwtool?branch=master)

recount.bwtool
==============

Compute coverage matrices from [recount](https://jhubiostatistics.shinyapps.io/recount/) using [bwtool](https://github.com/CRG-Barcelona/bwtool). This makes it easy to explore regions beyond the genes and exons that are available in recount. For example, it can be used for annotation-agnostic differential expression analyses with the data from the recount project as described in the [paper](http://www.nature.com/nbt/journal/v35/n4/full/nbt.3838.html). This package was used for computing expressed regions in the GTEx data as described in this [pre-print](biorxiv.org/content/early/2017/06/03/145656).

For more information about `recount.bwtool` check the help page for the `coverage_matrix_bwtool()` function.

# Installation instructions

Get R 3.3.x from [CRAN](http://cran.r-project.org/). Also install [bwtool](https://github.com/CRG-Barcelona/bwtool/wiki). Check it's [installation instructions](https://github.com/CRG-Barcelona/bwtool/wiki#installation).

```R
## Install the dependencies from Bioconductor
source('http://bioconductor.org/biocLite.R')
biocLite(c('recount'))

## Then install recount.bwtool
biocLite('LieberInstitute/recount.bwtool')
```

## Install `bwtool` on SciServer

Thanks to [@BenLangmead](https://github.com/BenLangmead), you can install `bwtool` on SciServer Compute with these commands:

```bash
conda config --add channels conda-forge
conda config --add channels defaults
conda config --add channels r
conda config --add channels bioconda

conda install libpng

export CPATH="$CPATH:$HOME/miniconda3/include"
export LIBRARY_PATH="$LIBRARY_PATH:$HOME/miniconda3/lib"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/miniconda3/lib"

git clone https://github.com/CRG-Barcelona/libbeato.git
git clone https://github.com/CRG-Barcelona/bwtool.git
cd libbeato/
./configure --prefix=$HOME CFLAGS="-g -O0 -I${HOME}/include" LDFLAGS=-L${HOME}/lib
make
make install
cd ../bwtool/
./configure --prefix=$HOME CFLAGS="-g -O0 -I${HOME}/include" LDFLAGS=-L${HOME}/lib
make
make install
```

which would make `bwtool` available at `/home/idies/bin/bwtool`.

# Citation

Below is the citation output from using `citation('recount.bwtool')` in R. Please run this yourself to check for any updates on how to cite __recount.bwtool__.

To cite the __recount.bwtool__ package in publications use:

Ellis SE, Collado-Torres L, Jaffe AE and Leek JT (2017). “Improving the value of public RNA-seq expression data by phenotype prediction.” _bioRxiv_. doi:
10.1101/145656 (URL: http://doi.org/10.1101/145656), <URL: http://www.biorxiv.org/content/early/2017/06/03/145656>.

A BibTeX entry for LaTeX users is

```
@Article{,
    title = {Improving the value of public RNA-seq expression data by phenotype prediction},
    author = {Shannon E. Ellis and Leonardo Collado-Torres and Andrew E. Jaffe and Jeffrey T. Leek},
    year = {2017},
    journal = {bioRxiv},
    doi = {10.1101/145656},
    url = {http://www.biorxiv.org/content/early/2017/06/03/145656},
}
```

To cite __recount__ use `citation('recount')` in R and use:

Collado-Torres L, Nellore A, Kammers K, Ellis SE, Taub MA, Hansen KD, Jaffe AE, Langmead B and Leek JT (2017). “Reproducible RNA-seq analysis using
recount2.” _Nature Biotechnology_. doi: 10.1038/nbt.3838 (URL: http://doi.org/10.1038/nbt.3838), <URL:
http://www.nature.com/nbt/journal/v35/n4/full/nbt.3838.html>.

```
@Article{,
    title = {Reproducible RNA-seq analysis using recount2},
    author = {Leonardo Collado-Torres and Abhinav Nellore and Kai Kammers and Shannon E. Ellis and Margaret A. Taub and Kasper D. Hansen and Andrew E. Jaffe and Ben Langmead and Jeffrey T. Leek},
    year = {2017},
    journal = {Nature Biotechnology},
    doi = {10.1038/nbt.3838},
    url = {http://www.nature.com/nbt/journal/v35/n4/full/nbt.3838.html},
}
```

# Testing

Testing on Bioc-devel is feasible thanks to [R Travis](http://docs.travis-ci.com/user/languages/r/).
