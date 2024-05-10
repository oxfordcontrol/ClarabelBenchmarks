# Run benchmarks on SOCP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs
using ClarabelBenchmarks.ClarabelGPU

solvers = [Mosek,ClarabelGPU,ClarabelRs]
tag     = nothing
class   = "opf_large_socp"
verbose = false
time_limit = 3600.
rerun = true
plotlist = solvers
ok_status = ["OPTIMAL"]
machine = :local 
gpu_test = true

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist,
    ok_status = ok_status, gpu_test = gpu_test)

