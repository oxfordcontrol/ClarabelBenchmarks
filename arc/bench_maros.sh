#!/bin/bash

#SBATCH --job-name="Maros"
#SBATCH --output="Maros.out"
#SBATCH --error="Maros.err.out"

#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --partition=htc
#SBATCH --exclusive
#SBATCH --mail-type=ALL
#SBATCH --mail-user=paul.goulart@eng.ox.ac.uk

#SBATCH --array=$MODULE_Clarabel

export CLASS_KEY="maros" 

$DATA/julia 'include("arc_bench_script.jl")'