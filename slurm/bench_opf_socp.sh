#!/bin/bash

# generate Julia solver modules environment variables
source modules.sh

#the benchmark tests to run
export BENCHMARK_CLASS_KEY="opf_socp"

#the time limit for individual problems
export BENCHMARK_PROBLEM_TIME_LIMIT=300

#total runtime timeout per solver for this set of problems
export BENCHMARK_SLURM_TIME_LIMIT=11:00:00

#non standard partition since time limit exceeds short partition bound
export BENCHMARK_SLURM_PARTITION="short"

#the list of solvers to test   
export BENCHMARK_SOLVER_ARRAY="\
$MODULE_Clarabel,\
$MODULE_ClarabelRs,\
$MODULE_Mosek,\
$MODULE_Gurobi,\
$MODULE_ECOS,\
"

#makes a slurm configuration file and calls sbatch
source make_slurm_conf.sh $BENCHMARK_CLASS_KEY
