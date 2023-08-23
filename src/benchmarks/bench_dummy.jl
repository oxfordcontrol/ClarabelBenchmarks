# Run benchmarks on dummy problems.   For debugging only

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, OSQP, HiGHS, Hypatia
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,ClarabelRs,Mosek]
tag     = nothing
class   = "dummy"
verbose = false
time_limit = 10.
rerun = false


df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose, 
    tag = tag, 
    rerun = rerun)