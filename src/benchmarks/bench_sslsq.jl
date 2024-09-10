# Run benchmarks on our own SOCP benchmarks

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, HiGHS
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,OSQP,HiGHS]
class   = "sslsq"
verbose = false
time_limit = 120.
tag     = nothing
rerun   = false
plotlist = [Mosek,Clarabel,ClarabelRs,ECOS,Gurobi,HiGHS]


df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose,
    tag = tag,
    rerun = rerun,
    plotlist = plotlist)