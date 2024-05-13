# Run benchmarks on our own SOCP benchmarks

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools,Hypatia
using ClarabelRs

# solvers = [Mosek,Clarabel,ECOS,ClarabelRs,Hypatia]
solvers     = [Clarabel,ECOS]
tag         = nothing
class       = "entropy_maximization"
verbose     = true
time_limit  = 300.
rerun       = true
plotlist    = solvers

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)