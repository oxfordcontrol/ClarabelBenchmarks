# Run benchmarks on our own SOCP benchmarks

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, MosekTools
using ClarabelRs

solvers    = [Clarabel,ECOS]
tag        = nothing
class      = "logreg"
verbose    = true
time_limit = 300.
rerun      = true
plotlist   = solvers

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)