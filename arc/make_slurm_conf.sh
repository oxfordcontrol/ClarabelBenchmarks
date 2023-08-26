#!/bin/bash

# Define the SLURM configuration settings
content="#!/bin/bash

#SBATCH --job-name="${BENCHMARK_CLASS_KEY}" 
#SBATCH --output="${BENCHMARK_CLASS_KEY}_%A_%a.out"
#SBATCH --error="${BENCHMARK_CLASS_KEY}_%A_%a.err.out"               
#SBATCH --time="$BENCHMARK_SLURM_TIME_LIMIT"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mail-type=ALL
#SBATCH --mail-user=paul.goulart@eng.ox.ac.uk
#SBATCH --partition=devel
#SBATCH --array="$BENCHMARK_SOLVER_ARRAY"        

#load modules and define julia package env variables
source preamble.sh

$DATA/julia 'include(\"arc_bench_script.jl\")'
"

# Dump to a slurm configuration file
confFile="$1_slurm.conf"
echo "$content" > "$confFile"
echo "SLURM configuration written to \"$confFile\":"

# run sbatch with this configuration
sbatch $confFile
