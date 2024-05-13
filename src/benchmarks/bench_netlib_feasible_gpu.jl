# Run benchmarks on netlib feasible LPs

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, OSQP, HiGHS, Hypatia
using Gurobi, MosekTools
using ClarabelRs
using ClarabelBenchmarks.ClarabelGPU

solvers = [ClarabelGPU,Mosek,ClarabelRs,Gurobi]
class   = "netlib_feasible"
verbose = true
time_limit = 300.
rerun   = false

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, rerun = rerun, gpu_test = true)