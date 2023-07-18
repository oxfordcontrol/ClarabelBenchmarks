# Run benchmarks on CBLIB SOCP problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Mosek,Clarabel,ClarabelRs,ECOS] #, Hypatia]
class   = ["cblib_socp"]
verbose = false
time_limit = 120.
tag     = :nothing
rerun = false

df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose,
    tag = tag,rerun = rerun)