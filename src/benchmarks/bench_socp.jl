# Run benchmarks on our own SOCP benchmarks

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,ECOS,ClarabelRs] #,Hypatia]
solvers = [Clarabel]
class   = ["socp"]
exclude = [r"cblib_socp"] #done in separate bench_cblib_socp.jl
verbose = false
time_limit = 300.

tag     = :unit
rerun = false



df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose,
    exclude = exclude,
    tag = tag,rerun = rerun)