#!/bin/bash

# tasks for node used by both SLURM and Julia
TASKS_PER_NODE=2

# default subdirectory of ...results/jld2 for outputs.  Overrideable
# by setting $BENCHMARK_RESULTS_OUTPUTDIR
BENCHMARK_RESULTS_OUTPUTDIR_DEFAULT="foo"

#configure for output to default subdirectory if not user specified                                                                                                                                           
[ -z $BENCHMARK_RESULTS_OUTPUTDIR ] && BENCHMARK_RESULTS_OUTPUTDIR=$BENCHMARK_RESULTS_OUTPUTDIR_DEFAULT

# Define the SLURM configuration settings
content="#!/bin/bash

#SBATCH --job-name="${BENCHMARK_CLASS_KEY}" 
#SBATCH --output="out/${BENCHMARK_CLASS_KEY}_%A_%a.out"
#SBATCH --error="out/${BENCHMARK_CLASS_KEY}_%A_%a.err.out"               
#SBATCH --time="$BENCHMARK_SLURM_TIME_LIMIT"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node="$TASKS_PER_NODE"
#SBATCH --mail-type=ALL
#SBATCH --mail-user=paul.goulart@eng.ox.ac.uk
#SBATCH --constraint="cpu_sku:Platinum_8268,cpu_frq:2.90GHz,cpu_mem:3TB"                                                                                                                                      
#SBATCH --partition=long
#SBATCH --mem-per-cpu=32G
#SBATCH --qos=priority
#SBATCH --array="$BENCHMARK_SOLVER_ARRAY"

#load modules and define julia package env variables
source preamble.sh

#configure JLD2 target subdirectory 
export BENCHMARK_RESULTS_OUTPUTDIR="$BENCHMARK_RESULTS_OUTPUTDIR"

$DATA/julia -t $TASKS_PER_NODE arc_bench_script.jl
"


# Dump to a slurm configuration file
confFile="$1_slurm.conf"
echo "$content" > "$confFile"
echo "SLURM configuration written to \"$confFile\":"

# run sbatch with this configuration
sbatch $confFile
