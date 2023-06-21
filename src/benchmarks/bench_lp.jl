# Run benchmarks on LP test set

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs
using Tulip
using HiGHS
using Hypatia  

solvers = [ClarabelRs,Gurobi,Mosek,Clarabel,ECOS,HiGHS] 
solvers = [Clarabel]
tag     = :unit
class   = ["lp"]
verbose = false
time_limit = 180.
rerun = true

df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun)