# Run benchmarks on SOCP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Mosek,Clarabel,ECOS,ClarabelRs]
tag     = nothing
class   = "hard_socp"
verbose = false
time_limit = 120.
rerun = false
plotlist = [Mosek,ClarabelRs,ECOS,Clarabel]
ok_status = ["OPTIMAL"]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist,
    ok_status = ok_status)

