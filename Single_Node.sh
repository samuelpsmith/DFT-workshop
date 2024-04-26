#!/bin/bash
#
#SBATCH --job-name=example_name.sh
#SBATCH --output=example_name.txt
#

## Slurm script for single-node (multicore) Gaussian calculation.
# Max cores (ntasks) that can be requested per node:
# Xena, 16; Wheeler, 8; Hopper, 32.
# Make sure that the # processors requested matches the number
# specified in the Gaussian .com input file invoked below.
#
# Set nodes=1 for single node execution. Adjust walltime request as needed.
# Note: multinode execution of Gaussian requires special scripting and
# instrumentation; nodes=1 only is allowed here; adjust ntasks to be the same
# as the value of nproc in the .com file you are submitting to g16 below.

#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --time=47:45:00
#SBATCH --partition=general
#SBATCH --mail-user=user@unm.edu
#SBATCH --mail-type=ALL


module load gaussian/g16


INPUT_FILE=$SLURM_SUBMIT_DIR/example_name.gjf
OUTPUT_FILE=$SLURM_SUBMIT_DIR/example_name.log


jobstart=$(date)
g16 $INPUT_FILE $OUTPUT_FILE


jobend=$(date)
echo "job_start:$jobstart"
echo "job_end:$jobend"
