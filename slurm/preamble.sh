#!/bin/bash

if [ "$HOSTNAME" == "fenway" ]; then
    echo "skipping ARC module loading"
else
    # load ARC modules here (but not Rust)
    module load Gurobi
    module load intel
fi

# builds enviroment variables for optimization packages 
# and assigns them numbers. Useful for SLURM arrays
source modules.sh
