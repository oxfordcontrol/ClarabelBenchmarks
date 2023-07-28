# Run benchmarks on netlib feasible LPs

# include any solvers you want to test 
using Clarabel, ECOS, OSQP, HiGHS, Hypatia
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,HiGHS]
class   = ["netlib_feasible"]
verbose = false
time_limit = 300.
rerun   = false



df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose, rerun = rerun)