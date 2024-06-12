# Run benchmarks on CBLIB ExpCone problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Hypatia, SCS
using Gurobi, MosekTools
using ClarabelRs
using ClarabelBenchmarks.ClarabelGPU
using ClarabelBenchmarks.MosekWithPresolve

solvers = [ClarabelGPU,MosekWithPresolve,Mosek,ClarabelRs]
tag     = nothing
class   = "cblib_large_pow"
verbose = true
time_limit = 300.
rerun = true
plotlist = solvers
machine = :local
gpu_test = true

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist, machine = machine, gpu_test = gpu_test)
