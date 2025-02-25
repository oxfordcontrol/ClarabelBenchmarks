
# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel
using SCS, MosekTools
using ClarabelRs

solvers = [Mosek,ClarabelRs]
tag     = nothing
class   = "sdplib"
verbose = false
time_limit = 1800.
rerun = false
plotlist = solvers

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, 
    tag = tag, 
    rerun = rerun,
    plotlist = plotlist)