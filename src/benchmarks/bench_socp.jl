# Run benchmarks on our own SOCP benchmarks

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Mosek,Clarabel,ECOS,ClarabelRs,Hypatia]
tag     = nothing
class   = "socp"
verbose = false
time_limit = 300.
rerun = false
plotlist = [Mosek,ClarabelRs,ECOS,Hypatia]

solvers = [Clarabel,Mosek]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    exclude = exclude,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)