#!/bin/bash

# generate Julia solver modules environment variables
source modules.sh

#the benchmark tests to run
export BENCHMARK_CLASS_KEY="qp"

#the time limit for individual problems
export BENCHMARK_PROBLEM_TIME_LIMIT=300

#total runtime timeout per solver for this set of problems
export BENCHMARK_SLURM_TIME_LIMIT=06:00:00

#the list of solvers to test   
export BENCHMARK_SOLVER_ARRAY="\
$MODULE_Clarabel,\
$MODULE_ClarabelRs,\
$MODULE_Mosek,\
$MODULE_ECOS,\
$MODULE_Gurobi,\
$MODULE_OSQP,\
$MODULE_SCS,\
$MODULE_HiGHS,\
$MODULE_Hypatia,\
$MODULE_ClarabelHSDE,\                                                                                                                     
$MODULE_ClarabelRsHSDE,\   
"

#makes a slurm configuration file and calls sbatch
source make_slurm_conf.sh $BENCHMARK_CLASS_KEY
