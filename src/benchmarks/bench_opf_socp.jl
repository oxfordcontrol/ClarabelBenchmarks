# Run benchmarks on SOCP problems from PowerModels.jl

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs

solvers = [Mosek,Clarabel,ECOS,ClarabelRs]
tag     = nothing
class   = "opf_socp"
verbose = false
time_limit = 120.
rerun = false
plotlist = [Mosek,ClarabelRs,ECOS,Clarabel]
ok_status = ["OPTIMAL","SLOW_PROGRESS","ALMOST_OPTIMAL"]

solvers = [Clarabel,Mosek]


df = ClarabelBenchmarks.benchmark(
    solvers, class;
    time_limit = time_limit,
    verbose = verbose, tag = tag, rerun = rerun,
    plotlist = plotlist,
    ok_status = ok_status)

# for some problems, none of the solvers produce an optimal 
# solution.   Assume that these are actually infeasible and 
# remove them from the dataframe

problems = unique(df.problem)
for p in problems
    if !any(df.problem .== p .&& df.status .∈ [ok_status])
        filter!(row -> row.problem != p, df)
    end
end