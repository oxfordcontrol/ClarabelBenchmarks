# Run benchmarks on LP test set

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs
using Tulip
using HiGHS
using Hypatia  
using ClarabelBenchmarks.ClarabelGPU,ClarabelBenchmarks.MosekWithPresolve

solvers = [ClarabelRs,ClarabelGPU,Gurobi,Mosek]
tag     = nothing
class   = "large_qp"
verbose = false
time_limit = 180.
rerun = false
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