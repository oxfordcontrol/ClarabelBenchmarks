# Run benchmarks on Maros-Meszaros problems
# with slightly negative eigenvalues corrected

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, OSQP, HiGHS, Hypatia
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,OSQP,Hypatia,HiGHS]
tag     = nothing
class   = "maros_shifted"
verbose = false
time_limit = 120.
rerun = false
plotlist = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,Hypatia,HiGHS]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)