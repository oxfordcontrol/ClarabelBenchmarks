# Run benchmarks on SOCP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,ClarabelRs,Mosek,ECOS]
tag     = nothing
class   = "exp"
verbose = false
time_limit = 1000.
rerun = false
plotlist = solvers
ok_status = ["OPTIMAL"]


df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist,
    ok_status = ok_status, gpu_test = gpu_test)

