# Run benchmarks on Maros-Meszaros problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs
#using Tulip

#use caution running these two because they are very slow for some problems
#using HiGHS, Hypatia

solvers = [ClarabelRs,Gurobi,Mosek,Clarabel,ECOS] 
solvers = [Clarabel,ClarabelRs,Mosek,Gurobi,ECOS]
class   = ["netlib_infeasible"]
verbose = false
time_limit = 300.
rerun   = false
ok_status = ["INFEASIBLE","DUAL_INFEASIBLE","PRIMAL_INFEASIBLE"]


df = ClarabelBenchmarks.bench_common(
    @__FILE__, solvers, class;
    time_limit = time_limit,
    verbose = verbose, rerun = rerun, 
    ok_status = ok_status)