# Run benchmarks on LP test set

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ECOS, Gurobi, MosekTools
using ClarabelRs
using Tulip
using HiGHS
using Hypatia  
using ClarabelBenchmarks.ClarabelGPU
using TimerOutputs
using Printf
using JuMP

tag     = nothing
class   = "large_exp"
verbose = true
time_limit = 3600.
rerun = true
ok_status = ["OPTIMAL"]
machine = :local 
gpu_test = true

problems = keys(ClarabelBenchmarks.PROBLEMS[class])

num_exp = length(problems)
solve_time_1 = Vector{Float64}(undef,num_exp)
solve_time_2 = Vector{Float64}(undef,num_exp)
iter_1 = Vector{Int64}(undef,num_exp)
iter_2 = Vector{Int64}(undef,num_exp)

#save data needed in a table
tables = Dict()
tables[:problems] = keys(ClarabelBenchmarks.PROBLEMS[class])
tables[:full_time] = solve_time_1
tables[:mixed_time] = solve_time_2
tables[:full_iterations] = iter_1
tables[:mixed_iterations] = iter_2

for (i,example) in enumerate(problems)
    model1 = Model(Clarabel.Optimizer)
    set_optimizer_attribute(model1,"direct_solve_method",:cudss)
    ClarabelBenchmarks.PROBLEMS[class][example](model1)
    solver1 = model1.moi_backend.optimizer.model.optimizer.solver
    
    if solver1.solution.status === Clarabel.SOLVED
        tables[:full_time][i] = TimerOutputs.tottime(solver1.timers["solve!"])/1e9
        tables[:full_iterations][i] = solver1.info.iterations
    else
        tables[:full_time][i] = Inf
    end

    sleep(0.5)

    model2 = Model(Clarabel.Optimizer)
    set_optimizer_attribute(model2,"direct_solve_method",:cudssmixed)
    ClarabelBenchmarks.PROBLEMS[class][example](model2)
    solver2 = model2.moi_backend.optimizer.model.optimizer.solver
    
    if solver2.solution.status === Clarabel.SOLVED
        tables[:mixed_time][i] = TimerOutputs.tottime(solver2.timers["solve!"])/1e9
        tables[:mixed_iterations][i] = solver2.info.iterations
    else
        tables[:mixed_time][i] = Inf
    end

end


filename = "bench_mixed_" * class * "_detail_table.tex"
filename = joinpath(ClarabelBenchmarks.get_path_results_tables(),filename)
io = open(filename, "w");

println(io,"\\scriptsize")

println(io,"\\begin{longtable}" * "{||l" * "||cc"^(3) * "||}")

println(io,"\\caption{\\detailtablecaption}")
println(io,"\\label{table:mixed_$class}")
println(io,"\\\\")

#print primary headerss
for label in ["iterations","time per iteration(s)", "total time (s)"]
    print(io,"& \\multicolumn{2}{c||}{\\underline{$label}}");
end 
print(io, "\\\\[2ex] \n")

#print secondary headers
print(io, "Problem");
print(io," & Clarabel & Mixed GPU"^(3));
print(io, "\\\\[1ex]\n")

println(io,"\\hline")
println(io,"\\endhead")

for (i,problem) in enumerate(problems)

    problem = replace(problem,"_" => raw"\_")
    print(io, "\\sc{" * problem * "}")

    iter_full       = tables[:full_iterations][i]
    total_time_full = tables[:full_time][i]
    avg_time_full   = ""
    iter_mixed       = tables[:mixed_iterations][i]
    total_time_mixed = tables[:mixed_time][i]
    avg_time_mixed   = ""

    if(!isfinite(total_time_full))
        iter_full = "-"
        total_time_full = "-"
        avg_time_full = "-"
    else 
        total_time_full = @sprintf("%4.3g",total_time_full)
        avg_time_full = @sprintf("%4.3g",parse(Float64, total_time_full)/iter_full)
    end

    if(!isfinite(total_time_mixed))
        iter_mixed = "-"
        total_time_mixed = "-"
        avg_time_mixed = "-"
    else 
        total_time_mixed = @sprintf("%4.3g",total_time_mixed)
        avg_time_mixed = @sprintf("%4.3g",parse(Float64, total_time_mixed)/iter_mixed)
    end

    print(io, " & $iter_full & $iter_mixed & $avg_time_full & $avg_time_mixed &  $total_time_full & $total_time_mixed")

    print(io, "\\\\ \n")

end 


println(io,"\\end{longtable}")

close(io)