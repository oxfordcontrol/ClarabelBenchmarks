# Run benchmarks on SDP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel
using SCS, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,SCS,Hypatia]
tag     = nothing
class   = "sdp"
verbose = false
time_limit = 300.
rerun = false
plotlist = solvers

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)