# Run benchmarks on netlib infeasible LPs

# include any solvers you want to test 
using Clarabel, ECOS, OSQP, HiGHS, Hypatia
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,HiGHS]
class   = "netlib_infeasible"
verbose = false
time_limit = 300.
rerun   = false

# these status codes count as "success" for  
# the purpose of performance profiles
ok_status = ["INFEASIBLE","DUAL_INFEASIBLE","PRIMAL_INFEASIBLE"]

df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose, rerun = rerun,
    ok_status = ok_status)