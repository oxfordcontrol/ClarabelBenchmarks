using Plots, JLD2,DataFrames, ColorSchemes

function get_style(solver,tag)

    cs = ColorSchemes.seaborn_colorblind
    solvers = ["Clarabel","Mosek","Gurobi","ClarabelRs","ECOS","Hypatia","HiGHS","OSQP"]

    # get the color for the solver in the order above
    idx = findfirst(solver .== solvers) 
    if(isnothing(idx)) 
        idx = length(solvers) + 1
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

function performance_profile(df; plotlist = nothing, ok_status = nothing)

    best     = Dict()
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
        ylims=[0,1.],
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



function time_profile(df; plotlist = nothing)

    problems = unique(df.problem)
    tagged_solvers_all = collect(zip(df.solver,df.tag))
    tagged_solvers_unique  = unique(tagged_solvers_all)
    tagged_solvers_unique = sort(tagged_solvers_unique, by = (x) -> x[1])

    if(!isnothing(plotlist))
        tagged_solvers_unique = filter(x -> x[1] ∈ String.(Symbol.(plotlist)), tagged_solvers_unique)
    end

    ok = ["OPTIMAL","ALMOST_OPTIMAL","LOCALLY_SOLVED"]

    h = plot()
    n = length(problems)

    min_time = minimum(df[df.status .∈ [ok], :].solve_time) 
    max_time = maximum(df[df.status .∈ [ok], :].solve_time) 
    min_time = 10^(floor(log10(min_time)))
    max_time = 10^(ceil(log10(max_time)))
    time_ticks = (10.).^(log10(min_time):1.:log10(max_time))


    #make a plot
    for tagged_solver in tagged_solvers_unique


        thisdf = df[df.solver .== tagged_solver[1] .&& df.tag .== tagged_solver[2], :]
        nattempts = nrow(thisdf)
        
        t = thisdf[thisdf.status .∈ [ok], :].solve_time 
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