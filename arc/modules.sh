#!/bin/bash

# This script creates environment variables for each module and
# assigns them numbers.   This is useful for creating arrays of
# arguments in SLURM since it only takes integer arguments 

# Input list of words separated by spaces
module_list="Clarabel ClarabelRs Mosek Gurobi ECOS OSQP SCS HiGHS Hypatia Tulip Clarabel128"

# Split the module list into an array of words
IFS=" " read -r -a modules <<< "$module_list"

# Counter for assigning consecutive numbers
counter=1

# Loop through the modules and create environment variables
for module in "${modules[@]}"; do

    # create a variable with the module name and assign it a number
    export "MODULE_$module"="$counter"

    # create another variable mapping numbers back to names 
    export "MODULE_NUMBER_$counter"="$module"

    # Increment the counter for the next variable
    ((counter++))
done

