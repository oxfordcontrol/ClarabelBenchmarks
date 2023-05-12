# Run benchmarks on CBLIB ExpCone problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
# using ClarabelRs

solvers = [Mosek,Clarabel,ECOS] #, ClarabelRs, Hypatia]
class   = ["cblib_exp"]
verbose = false
time_limit = 300.

df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose)
