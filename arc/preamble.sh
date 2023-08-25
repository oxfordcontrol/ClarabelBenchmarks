#!/bin/bash

# load ARC modules here (but not Rust)
module load Gurobi
module load intel

# builds enviroment variables for optimization packages 
# and assigns them numbers. Useful for SLURM arrays
source preamble.sh