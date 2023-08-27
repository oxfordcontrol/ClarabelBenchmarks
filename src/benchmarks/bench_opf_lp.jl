# Run benchmarks on LP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, OSQP, HiGHS, Hypatia
using Gurobi, MosekTools
using ClarabelRs

solvers = [Clarabel,Mosek,ClarabelRs,ECOS,Gurobi,HiGHS]
tag     = nothing
class   = "opf_lp"
verbose = false
time_limit = 120.
rerun = false
plotlist = [Mosek,ClarabelRs,ECOS,Gurobi,HiGHS]

df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist)

# for some problems, none of the solvers produce an optimal 
# solution.   Assume that these are actually infeasible and 
# remove them from the dataframe

problems = unique(df.problem)
for p in problems
    if !any(df.problem .== p .&& df.status .== "OPTIMAL")
        filter!(row -> row.problem != p, df)
    end
end