# Run benchmarks on Maros-Meszaros problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

# these additional solvers have very bad performance in the 
# maros tests and will need to be excluded or run separately
# using HiGHS, Hypatia

solvers = [ClarabelRs,Gurobi,Mosek,Clarabel,ECOS] #,OSQP,ClarabelRs,HiGHS,Hypatia]
class   = ["maros"]
verbose = true
time_limit = 120.

df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose)