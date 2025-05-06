# Run benchmarks on SOCP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS
using MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS]
tag     = nothing
class   = "opf_socp"
verbose = false
time_limit = 300.
rerun = false
plotlist = [Clarabel,Mosek,ClarabelRs,ECOS]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, 
    tag = tag, 
    rerun = rerun,
    plotlist = plotlist)

