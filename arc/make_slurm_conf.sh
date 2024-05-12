 #!/bin/bash

# tasks for node used by both SLURM and Julia
TASKS_PER_NODE=2

# default subdirectory of ...results/jld2 for outputs.  Overrideable
# by setting $BENCHMARK_RESULTS_OUTPUTDIR
BENCHMARK_RESULTS_OUTPUTDIR_DEFAULT="chordal_faer"

# default slurm partitiont.  Overrideable by setting $BENCHMARK_SLURM_PARTITION                                                                                     
BENCHMARK_SLURM_PARTITION_DEFAULT="short"

#--------------------------------------
#--------------------------------------

#configure for output to default subdirectory if not user specified                                                                                                                                           
[ -z $BENCHMARK_RESULTS_OUTPUTDIR ] && BENCHMARK_RESULTS_OUTPUTDIR=$BENCHMARK_RESULTS_OUTPUTDIR_DEFAULT

#configure for output to default subdirectory if not user specified
[ -z $BENCHMARK_SLURM_PARTITION ] && BENCHMARK_SLURM_PARTITION=$BENCHMARK_SLURM_PARTITION_DEFAULT

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
#SBATCH --partition="$BENCHMARK_SLURM_PARTITION"
# #SBATCH --exclusive
#SBATCH --mem-per-cpu=64G
#SBATCH --array="$BENCHMARK_SOLVER_ARRAY"

#load modules and define julia package env variables
source preamble.sh

#configure JLD2 target subdirectory 
export BENCHMARK_RESULTS_OUTPUTDIR="$BENCHMARK_RESULTS_OUTPUTDIR"

$DATA/julia -t $TASKS_PER_NODE arc_bench_script.jl
"

#dump the julia / rust branches
echo "Julia config...."
git -C $HOME/projects/clarabel/julia status

echo "Rust config...."
git -C $HOME/projects/clarabel/rust status


# Dump to a slurm configuration file
confFile="$1_slurm.conf"
echo "$content" > "$confFile"
echo "SLURM configuration written to \"$confFile\":"
echo "writing outputs to target: $BENCHMARK_RESULTS_OUTPUTDIR"

# run sbatch with this configuration
sbatch -v $confFile
