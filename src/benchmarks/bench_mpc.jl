# Run benchmarks on Maros-Meszaros problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS,OSQP, HiGHS, Hypatia
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,OSQP,Hypatia,HiGHS]
solvers = [Gurobi]
tag     = nothing
class   = ["mpc"]
verbose = true
time_limit = 10.
rerun = false

df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun)