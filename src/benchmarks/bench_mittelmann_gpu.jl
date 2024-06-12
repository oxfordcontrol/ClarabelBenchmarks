# Run benchmarks on Mittelmann LP problems from 
"https://plato.asu.edu/ftp/lptestset/"

# include any solvers you want to test 
using JuMP
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, HiGHS
using Gurobi, MosekTools
using ClarabelRs
using ClarabelBenchmarks.ClarabelGPU,ClarabelBenchmarks.MosekWithPresolve

solvers = [ClarabelGPU,Mosek,Gurobi]
tag     = nothing
class   = "mittelmann_lp"
verbose = true
time_limit = 500.0
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


