# Run benchmarks on SDP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel
using SCS, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,SCS]
tag     = nothing
class   = "opf_sdp"
verbose = false
time_limit = 300.
rerun = false
plotlist = [ClarabelRs,Mosek,SCS]

df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)