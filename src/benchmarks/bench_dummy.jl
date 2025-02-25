# Run benchmarks on dummy problems.   For debugging only

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames

using MosekTools, Clarabel, ClarabelRs, Gurobi, ECOS, HiGHS
solvers = [MosekTools, Clarabel, ClarabelRs, Gurobi, ECOS, HiGHS]
tag     = nothing
class   = "dummy"
verbose = false
time_limit = 10.
rerun = false


df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, 
    tag = tag, 
    rerun = rerun)

