# Run benchmarks on netlib feasible LPs

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, HiGHS
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,HiGHS]
tag     = nothing
class   = "netlib_feasible"
verbose = false
time_limit = 300.
rerun   = false
plotlist = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,HiGHS]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, 
    tag = tag, 
    rerun = rerun,
    plotlist = plotlist)