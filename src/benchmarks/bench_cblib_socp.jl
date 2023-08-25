# Run benchmarks on CBLIB SOCP problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Mosek,Clarabel,ECOS,ClarabelRs]
tag     = nothing
class   = "cblib_socp"
verbose = false
time_limit = 300.
rerun = false
plotlist = [Mosek,ClarabelRs,ECOS]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)