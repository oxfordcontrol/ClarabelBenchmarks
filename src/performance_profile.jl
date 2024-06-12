using Plots, JLD2,DataFrames, ColorSchemes, StatsBase

function get_style(solver,tag)

    cs = ColorSchemes.tab10
    solvers = ["ClarabelBenchmarks.ClarabelGPU","ClarabelBenchmarks.MosekWithPresolve","Clarabel","Mosek","Gurobi","ClarabelRs","ECOS","Hypatia","HiGHS","OSQP","SCS","Tulip"]

    # get the color for the solver in the order above
    idx = findfirst(solver .== solvers) 
    if(isnothing(idx)) 
        idx = length(solvers)
    end 
    color = cs[idx]

    #untagged solvers are solid  
    if(isnothing(tag))
        line = :solid
    else 
        line = :dash
    end

    #cleanup solver strings 
    solver = solver == "Clarabel"   ? "Clarabel (Julia)" : solver
    solver = solver == "ClarabelRs" ? "Clarabel (Rust)"  : solver
    solver = solver == "ClarabelBenchmarks.ClarabelGPU"   ? "ClarabelGPU" : solver
    solver = solver == "ClarabelBenchmarks.MosekWithPresolve"   ? "Mosek*" : solver
    if !isnothing(tag) && tag != :nothing
        solver = solver * " : " * string(tag) 
    end    

    label = solver
    linewidth = 2

    return Dict(:color => color, 
                :line => line,
                :label => label, 
                :linewidth => linewidth)

end

function drop_unsolvable!(df,ok_status)

    #solver is assumed solvable if *any* solver could achieve ok_status
    #remove the unsolvable ones
    problems = unique(df.problem)
    for p in problems
        if !any(df.problem .== p .&& df.status .∈ [ok_status])
                filter!(row -> row.problem != p, df)
        end
    end
end 

function performance_profile(df; plotlist = nothing, ok_status = nothing, filter_solvable=true)

    best = Dict()
    df = deepcopy(df)
    tagged_solvers_all = collect(zip(df.solver,df.tag))
    tagged_solvers_unique  = unique(tagged_solvers_all)
    tagged_solvers_unique = sort(tagged_solvers_unique, by = (x) -> x[1])

    if(!isnothing(plotlist))
        tagged_solvers_unique = filter(x -> x[1] ∈ String.(Symbol.(plotlist)), tagged_solvers_unique)
        df = df[df.solver .∈ [String.(Symbol.(plotlist))],:]
    end

    if(isnothing(ok_status))
        ok_status = ["OPTIMAL"]
    end

    #solver is assumed solvable if *any* solver could achieve ok_status
    #remove the unsolvable ones
    if filter_solvable
        drop_unsolvable!(df,ok_status)
    end 

    #all remaining problems
    problems = unique(df.problem)

    #find the best time for each problem 
    for problem in problems 
        results = df[df.problem .== problem,:]
        optonly = results[in.(results.status, [ok_status]) ,:]
        if(size(optonly)[1] == 0)
            tmin = Inf 
        else 
            tmin = minimum(optonly.solve_time)
        end 
        best[problem] = tmin
    end 

    #compute performance levels of each solver/problem
    pp = deepcopy(df)
    pp.pratio .= Inf
    for i in 1:(size(pp)[1])
        row = pp[i,:]
        if row.status ∈ ok_status
            row.pratio = row.solve_time  / best[row.problem]
        end
    end


    perf_levels = (10.).^(0:0.01:3)

    h = plot()
    n = length(problems)
    #make a plot
    for tagged_solver in tagged_solvers_unique

        t = pp[pp.solver .== tagged_solver[1] .&& pp.tag .== tagged_solver[2], :].pratio
        y = [sum(t .< p)/n for p in perf_levels]

        style = get_style(tagged_solver[1],tagged_solver[2])
        plot!(h, perf_levels,y; style...)
    end

    xaxis!(h, :log10)
    plot!(h,
        titlefontsize = 8,
        xlabelfontsize = 8,
        ylabelfontsize = 8,
        legendfontsize = 6,
        xlims=[1,100],
        ylims=[0,1.001],
        xticks=[1,10,100,100],
        yticks=0.0:0.2:1.0,
        minorgrid=true,
        legend_position = :bottomright,
        title  = "Performance Ratio",
        xlabel = "Performance Ratio",
        ylabel = "Ratio of problems solved",
        )

    display(h)

    return h

end



function time_profile(df; plotlist = nothing, ok_status = nothing)

    df = deepcopy(df)

    problems = unique(df.problem)
    tagged_solvers_all = collect(zip(df.solver,df.tag))
    tagged_solvers_unique  = unique(tagged_solvers_all)
    tagged_solvers_unique = sort(tagged_solvers_unique, by = (x) -> x[1])

    if(!isnothing(plotlist))
        tagged_solvers_unique = filter(x -> x[1] ∈ String.(Symbol.(plotlist)), tagged_solvers_unique)
    end

    if(isnothing(ok_status))
        ok_status = ["OPTIMAL"]
    end

    #solver is assumed solvable if *any* solver could achieve ok_status
    #remove the unsolvable ones
    drop_unsolvable!(df,ok_status)

    #all remaining problems
    problems = unique(df.problem)


    h = plot()
    n = length(problems)

    min_time = minimum(df[df.status .∈ [ok_status], :].solve_time) 
    max_time = maximum(df[df.status .∈ [ok_status], :].solve_time) 
    min_time = 10^(floor(log10(min_time)))
    max_time = 10^(ceil(log10(max_time)))
    time_ticks = (10.).^(log10(min_time):1.:log10(max_time))


    #make a plot
    for tagged_solver in tagged_solvers_unique


        thisdf = df[df.solver .== tagged_solver[1] .&& df.tag .== tagged_solver[2], :]
        nattempts = nrow(thisdf)
        
        t = thisdf[thisdf.status .∈ [ok_status], :].solve_time 
        t = sort(t) 
        y = collect(1:length(t)) / nattempts
        t = [min_time; t; max_time]
        y = [0.0; y; y[end]]

        style = get_style(tagged_solver[1],tagged_solver[2])
        plot!(h, t,y;  style...)


    end

    xaxis!(h, :log10)
    plot!(h,
        titlefontsize = 8,
        xlabelfontsize = 8,
        ylabelfontsize = 8,
        legendfontsize = 6,
        xlims=[min_time,max_time],
        ylims=[0,1.],
        xticks=time_ticks,
        yticks=0.0:0.2:1.0,
        minorgrid=true,
        legend_position = :bottomright,
        title  = "Solution time profile",
        xlabel = "Solve time t",
        ylabel = "Fraction of problems solved within t",
        )

    display(h)

    return h

end

function sgm(t,k)

    exp(mean(log.(t .+ k))) - k

end 


function shifted_geometric_means(df; plotlist = nothing, ok_status = nothing, max_time = 300)

    k = 1.0

    df = deepcopy(df)
    solvers = unique(df.solver)
    sgm_optimal = Float64[]
    sgm_almost = Float64[]
    failrate_optimal = Float64[]
    failrate_almost = Float64[]

    println("Solvers are $solvers 1")
    println("plotlist is ", plotlist)

    println("type of plotlist ", typeof(plotlist))

    
    if(!isnothing(plotlist))
        solvers = filter(x -> x ∈ String.(Symbol.(plotlist)), solvers)
    end

    solvers = sort(solvers)

    println("Solvers are $solvers 1b")

    if all(["Clarabel","ClarabelRs"] .∈ [solvers])  #assumes we will be first alpha
        solvers = sort(setdiff(solvers, ["Clarabel","ClarabelRs"]))
        println("Solvers are $solvers 1c")
        solvers = [["ClarabelRs","Clarabel"];solvers]
    end

    if(isnothing(ok_status))
        ok_status = ["OPTIMAL"]
    end
    

    println("Solvers are $solvers 2")
    
    almost_ok_status = ["ALMOST_OPTIMAL"]
    if("OPTIMAL" ∈ [ok_status])
        almost_ok_status = ["ALMOST_OPTIMAL","SLOW_PROGRESS","LOCALLY_SOLVED"]
    end
    if("INFEASIBLE" ∈ [ok_status])
        almost_ok_status = ["ALMOST_INFEASIBLE"]
    end

    #solver is assumed solvable if *any* solver could achieve ok_status
    #remove the unsolvable ones
    drop_unsolvable!(df,ok_status)

    #all remaining problems
    problems = unique(df.problem)
    n = length(problems)

    println("Solvers are $solvers 3")


    for solver in solvers 

        println("Solver is ... $solver")

        thisdf = df[df.solver .== solver, :]
        @assert n == nrow(thisdf) 
        thisdf[ismissing.(thisdf.solve_time), :].status .= max_time 
    
        # enforce max solve time cap
        times_optimal = min.(thisdf.solve_time,max_time)
        times_almost  = min.(thisdf.solve_time,max_time)

        #round up to max time for bad solvers 
        is_not_optimal = thisdf.status .∉ [ok_status]
        is_not_almost  = thisdf.status .∉  [union(almost_ok_status,ok_status)]
        times_optimal[is_not_optimal,:] .= max_time
        times_almost[is_not_almost,:] .= max_time

        #compute shited geometric means 
        push!(sgm_optimal, sgm(times_optimal,k))
        push!(sgm_almost , sgm(times_almost, k))

        #count the success rates 
        push!(failrate_optimal, mean(is_not_optimal))
        push!(failrate_almost, mean(is_not_almost))



    end 

    #normalize 
    sgm_optimal ./=  minimum(sgm_optimal; init=Inf)
    sgm_almost  ./=  minimum(sgm_almost;  init=Inf)

    sgm_optimal = round.(sgm_optimal; digits=2)
    sgm_almost = round.(sgm_almost; digits=2)

    failrate_optimal = round.(failrate_optimal; digits=3).*100
    failrate_almost = round.(failrate_almost; digits=3).*100

    out = DataFrame(
        solver = solvers, 
        sgm_optimal = sgm_optimal, 
        sgm_almost = sgm_almost,
        failrate_optimal = failrate_optimal,
        failrate_almost  = failrate_almost)

    out = permutedims(out, 1)

    return out 

end