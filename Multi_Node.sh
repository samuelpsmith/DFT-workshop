#!/bin/bash

## Multi-Node Gaussian Script
#

### 1. HEADER
# Contains job name and output file name. Job name is passed as a variable below, so it must be near the top.
# The output file is a .txt file where all outputs from this script are passed for easy review. Prevents certain other .out files from being created. 
# These are the only two lines that will be different for every job, so it is convenient for them to be up top.
# Job name should not have periods (.) in it. Certain other special characters / ~ | etc. might cause issues as well.
# Your job name will be passed as the input and output file name. I believe this is organizationally prudent but you may edit this script to manually fill those
# filenames if you so desire. 
#
#SBATCH --job-name=example_name
#SBATCH --output=example_name.txt
#

### 2. SLURM RESOURCES
# The SLURM BATCH statements below request resources from the SLURM scheduler. This text explains our choices.
# Resource limits can be found at: https://github.com/UNM-CARC/webinfo/blob/main/resource_limits.md
# Note that Quality of Service (QOS) limits may not yet be reflected in this document. 
#
## NODES AND CPUs
# Here, we request multiple nodes with ntasks-per-node=1. This runs one instance of Gaussian per node, and then allocates cpus-per-task to that instance.
# I believe this to be the most effecient parellization scheme for Gaussian jobs. 
# In single-node Gaussian, usually cpus per task can usually be handled intelligently by Guassian even if we only pass ntasks (not ntasks-per-node),
# but we seem to need to be explicit in multi-node jobs.
#
## TIME LIMITS AND BACK-FILL SCHEDULING
# On Hopper, sometimes fairly complicated jobs can complete under the maximum time limit. Setting your jobs to complete within reasonable limits is 
# important for good stewardship of our resources and helps everyone! Requesting time and resources intelligently allows the scheduler to possibly back-fill your job.
# However, requesting less than the maximum number of CPUs on node does not seem to help with backfilling, as most people request all CPUs on a node. 
# Of course, for maximum effeciency, you should always endeavor to use all CPUs on a node, unless in rare case such as testing multi-node jobs in a QOS limited debug queue. 
# It is more difficult for a scheduler to back-fill multi-node calculations on Hopper than on Wheeler, as there are simply fewer nodes. 
# IF YOU REQUEST 48:00:00, YOU WILL LIKELY HAVE CHK FILE ISSUES. Gaussian doesn't exit gracefully when it reaches the hard limit. 
# To overcome this issue, you can request a few minutes less, such as 47:45:00, which leaves a wide buffer for a graceful exit. 
#
## MEMORY
# It is reasonable to request nearly all the memory on the node. I aim for somwhere around 80-90%, but I think you can push up to 94-96% before facing technical issues.
# The exact limits are likely cluster and node hardware dependent. You must therefore leave some memory for the node to complete non-job tasks such as scheduling. 
# YOU MUST SPECIFY LESS THAN YOUR REQUESTED MEMORY IN YOUR GAUSSIAN JOB FILE (.gjf, .com). This is because Gaussian handles memory poorly, and will almost always run over
# the limit given in the .gjf or .com file. By telling Gaussian in the .gjf that it has 1-2Gb less than requested in SLURM BATCH, you prevent many memory issues.
# If you are getting QOS limit errors, it may be due to overall per-person limits on the cluster if you are running multiple jobs.
#
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --time=15:45:00
#SBATCH --partition=general
#SBATCH --mail-user=ssmith43@unm.edu
#SBATCH --mem=60Gb
#SBATCH --mail-type=ALL
#

### 3. BATCH SCRIPT
# The following script submits a job given the information above. It is commented line by line for clarity. 

# Store current working directory (the submit directory) for later use & print for log and debug purposes.
WRKDIR=$(pwd)
echo "Working directory: $WRKDIR"

# Load Gaussian and its dependencies
module load gaussian/g16

# Make linda print verbose messages - mostly of interest to the CARC folks. 
export GAUSS_LFLAGS="-v"

# Reformat the SLURM provided list of compute nodes to a format Gaussian can understand
# i.e. remove duplicates and replace newlines with commas
export GAUSS_WDEF=$(cat $CARC_NODEFILE | uniq | sed -z 's/\n/,/g;s/,$/\n/')

# Tell Linda to use as many nodes as requested by the user & report.
export GAUSS_PDEF=$SLURM_CPUS_PER_TASK
echo "Parallelizing $GAUSS_PDEF processes across $GAUSS_WDEF nodes."

# Set the input and output file names from the job name. Job name cannot contain certain prohibited characters. 
INPUT_FILE=$SLURM_SUBMIT_DIR/${SLURM_JOB_NAME}.gjf
OUTPUT_FILE=$SLURM_SUBMIT_DIR/${SLURM_JOB_NAME}.log

# Run Gaussian & report exit status.
jobstart=$(date)
g16 $INPUT_FILE $OUTPUT_FILE
g_exit_status=$?

# Formcheck the checkpoint file to a readable .fchk file. 
formchk -3 ${WRKDIR}/${SLURM_JOB_NAME}.chk ${WRKDIR}/${SLURM_JOB_NAME}.fchk

# Print job info at the end of the .txt output file. Job start and job end are crucial for multi-node jobs, in which case Gaussian cannot estimate walltime correctly. 
jobend=$(date)
echo ${SLURM_JOB_NAME}
echo "job_start:$jobstart"
echo "job_end:$jobend"
echo "job_exit_status:$g_exit_status"
exit $g_exit_status

