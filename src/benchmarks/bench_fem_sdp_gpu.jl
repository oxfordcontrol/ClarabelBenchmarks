# Run benchmarks on LP test set

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs
using Tulip
using HiGHS
using Hypatia  
using ClarabelBenchmarks.ClarabelGPU,ClarabelBenchmarks.MosekWithPresolve

solvers = [ClarabelGPU,Mosek,MosekWithPresolve]
tag     = nothing
class   = "sdp_fem"
verbose = true
time_limit = 1000.
rerun = false
plotlist = solvers
ok_status = ["OPTIMAL"]
machine = :local 
gpu_test = true

df = ClarabelBenchmarks.benchmark_gpu(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist,
    ok_status = ok_status, gpu_test = gpu_test)