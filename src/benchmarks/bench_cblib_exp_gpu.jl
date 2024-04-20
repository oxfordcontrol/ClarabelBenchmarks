# Run benchmarks on CBLIB ExpCone problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Hypatia
using Gurobi, MosekTools
using ClarabelRs
using ClarabelBenchmarks.ClarabelGPU

solvers = [Clarabel,ClarabelGPU,Mosek,ClarabelRs]
tag     = nothing
class   = "cblib_large_exp"
verbose = false
time_limit = 300.
rerun = false
plotlist = solvers
machine = :local 
gpu_test = true

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist, machine = machine, gpu_test = gpu_test)
