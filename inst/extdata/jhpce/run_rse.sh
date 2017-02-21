#!/bin/bash

## Usage information:
# qrsh
# bash run_rse.sh --help
#
## Optional config:
# .send_emails: if this file exist, "-m e" will be used instead of "-m a"
# .queue: can specify the name of a queue you want to use. For example:
# echo "bluejay" > .queue
# Do not use "shared"

# Define variables
TEMP=$(getopt -o r:s:c:b:h --long regions:,sumsdir:,cores:,bed:,help -n 'step7-makeRobjects' -- "$@")
eval set -- "$TEMP"

BED=""
CORES=1

while true; do
    case "$1" in
        -r|--regions)
            case "$2" in
                "") shift 2 ;;
                *) REGIONS=$2 ; shift 2;;
            esac;;
        -s|--sumsdir)
            case "$2" in
                "") shift 2 ;;
                *) SUMSDIR=$2 ; shift 2;;
            esac;;
        -c|--cores)
            case "$2" in
                "") CORES="1" ; shift 2;;
                *) CORES=$2; shift 2;;
            esac ;;
        case "$2" in
            "") BED="" ; shift 2;;
            *) BED=$2; shift 2;;
        esac ;;
        -h|--help)
            echo -e "Usage:\nShort options:\n  bash run_rse.sh -r -s -c (default:1) -b (optional) \nLong options:\n  bash run_rse.sh --regions --sumsdir --cores (default:1) --bed (optional)"; exit 0; shift ;;
            --) shift; break ;;
        *) echo "Incorrect options!"; exit 1;;
    esac
done

## Try running R. If it fails it means that the user is on the login node.
Rscript -e "Sys.time()" &> .try_load_R
LOGNODE=$(grep force-quitting .try_load_R | wc -l)
if [ ${LOGNODE} != "0" ]
then
    echo "**** You are on the login node. Use qrsh to run this script ****"
    date
    exit 1
fi
rm .try_load_R

SHORT="recount-bwtool-single"
RIGHTNOW=$(date "+%Y-%m-%d")
sname="${SHORT}.${RIGHTNOW}"
MAINDIR=${PWD}

if [ -f ".send_emails" ]
then
    EMAIL="e"
else
    EMAIL="a"
fi

if [ -f ".queue" ]
then
    SGEQUEUE="$(cat .queue),"
else
    SGEQUEUE=""
fi

if [[ ${BED} == "" ]]
then
    BED="${SUMSDIR}/recount.bwtool-${RIGHTNOW}.bed"
    echo "**** Creating ${BED} with the regions ****"
    mkdir -p ${SUMSDIR}
    Rscript -e "library('rtracklayer'); library('GenomicRanges'); reg_load <- function(regpath) { regname <- load(regpath); get(regname) }; export(reg_load('${REGIONS}'), con = '${BED}', format='BED')"
fi

Rscript -e "writeLines(system.file('extdata', 'jhpce', package = 'recount.bwtool'), '.recount.bwtool')"
SCRIPTPATH=$(cat .recount.bwtool)

mkdir -p logs

# Construct shell files
echo "Creating script ${sname}"
cat > ${MAINDIR}/.${sname}.sh <<EOF
#!/bin/bash
#$ -cwd
#$ -pe local ${CORES}
#$ -l ${SGEQUEUE}mem_free=2G,h_vmem=3G,h_fsize=100G
#$ -N ${sname}
#$ -o ${MAINDIR}/logs/${SHORT}.\$TASK_ID.txt
#$ -e ${MAINDIR}/logs/${SHORT}.\$TASK_ID.txt
#$ -m ${EMAIL}
#$ -t 1-2034
#$ -tc 100
echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: \${USER}"
echo "Job id: \${JOB_ID}"
echo "Job name: \${JOB_NAME}"
echo "Hostname: \${HOSTNAME}"
echo "Task id: \${TASK_ID}"

Rscript ${SCRIPTPATH}/single_rse.R -p \${TASK_ID} -r ${REGIONS} -s ${SUMSDIR} -c ${CORES} -b ${BED}

echo "**** Job ends ****"
date
EOF

call="qsub .${sname}.sh"
echo $call
$call


## Similar script but with more memory for GTEx and TCGA
SHORT="recount-bwtool-large"
sname="${SHORT}.${RIGHTNOW}"
echo "Creating script ${sname}"
cat > ${MAINDIR}/.${sname}.sh <<EOF
#!/bin/bash
#$ -cwd
#$ -pe local ${CORES}
#$ -l ${SGEQUEUE}mem_free=4G,h_vmem=5G,h_fsize=100G
#$ -N ${sname}
#$ -o ${MAINDIR}/logs/${SHORT}.\$TASK_ID.txt
#$ -e ${MAINDIR}/logs/${SHORT}.\$TASK_ID.txt
#$ -m ${EMAIL}
#$ -t 2035-2036
#$ -tc 2
echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: \${USER}"
echo "Job id: \${JOB_ID}"
echo "Job name: \${JOB_NAME}"
echo "Hostname: \${HOSTNAME}"
echo "Task id: \${TASK_ID}"

Rscript ${SCRIPTPATH}/single_rse.R -p \${TASK_ID} -r ${REGIONS} -s ${SUMSDIR} -c ${CORES} ${BEDARG}

echo "**** Job ends ****"
date
EOF

call="qsub .${sname}.sh"
echo $call
$call


SHORT="recount-bwtool-merge"
sname="${SHORT}.${RIGHTNOW}"
echo "Creating script ${sname}"
cat > ${MAINDIR}/.${sname}.sh <<EOF
#!/bin/bash
#$ -cwd
#$ -l ${SGEQUEUE}mem_free=100G,h_vmem=120G,h_fsize=100G
#$ -N ${sname}
#$ -m ${EMAIL}
#$ -o ${MAINDIR}/logs/${SHORT}.txt
#$ -e ${MAINDIR}/logs/${SHORT}.txt
echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: \${USER}"
echo "Job id: \${JOB_ID}"
echo "Job name: \${JOB_NAME}"
echo "Hostname: \${HOSTNAME}"

Rscript ${SCRIPTPATH}/merge_sre.R

echo "**** Job ends ****"
date
EOF

call="qsub .${sname}.sh"
echo $call
$call

