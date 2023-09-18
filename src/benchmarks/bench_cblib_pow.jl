# Run benchmarks on CBLIB ExpCone problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Hypatia, SCS
using Gurobi, MosekTools
using ClarabelRs

solvers = [Mosek,Clarabel,ClarabelRs]
tag     = nothing
class   = "cblib_pow"
verbose = false
time_limit = 300.
rerun = false
plotlist = solvers

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)
