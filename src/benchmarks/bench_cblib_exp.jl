# Run benchmarks on CBLIB ExpCone problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Hypatia
using Gurobi, MosekTools
using ClarabelRs

solvers = [Mosek,Clarabel,ECOS,ClarabelRs,Hypatia]
tag     = nothing
class   = "cblib_exp"
verbose = false
time_limit = 300.
rerun = false
plotlist = [Mosek,ClarabelRs,ECOS,Hypatia]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)
