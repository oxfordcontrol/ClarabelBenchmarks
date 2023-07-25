# Run benchmarks on our own SOCP benchmarks

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,ECOS,ClarabelRs,Mosek,Gurobi] #,Hypatia]
solvers = [Clarabel]
class   = ["sslsq"]
verbose = false
time_limit = 300.
tag = :ma57
rerun = false
plotlist = [Clarabel,Mosek,ClarabelRs,ECOS] 




df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose,
    tag = tag,
    rerun = rerun,
    plotlist = plotlist)