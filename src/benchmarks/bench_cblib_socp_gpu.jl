# Run benchmarks on CBLIB SOCP problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs
using ClarabelBenchmarks.ClarabelGPU

solvers = [ClarabelGPU,Mosek,ClarabelRs]
tag     = nothing
class   = "cblib_large_socp"
verbose = false
time_limit = 3600.
rerun = false
plotlist = solvers
machine = :local 
gpu_test = true

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist, gpu_test = gpu_test)