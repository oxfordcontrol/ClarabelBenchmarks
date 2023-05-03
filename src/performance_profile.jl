using Plots, JLD2,DataFrames

function performance_profile(df)

    best     = Dict()
    problems = unique(df.problem)
    solvers  = unique(df.solver)

    ok = ["OPTIMAL","ALMOST_OPTIMAL","LOCALLY_SOLVED"]

    #find the best time for each problem 
    for problem in problems 
        results = df[df.problem .== problem,:]
        optonly = results[in.(results.status, [ok]) ,:]
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
        if row.status ∈ ok
            row.pratio = row.solve_time  / best[row.problem]
        end
    end


    perf_levels = (10.).^(0:0.01:3)

    h = plot()
    n = length(problems)
    #make a plot
    for solver in solvers
        t = pp[pp.solver .== solver, :].pratio
        y = [sum(t .< p)/n for p in perf_levels]
        plot!(h, perf_levels,y,label = solver, palette = :Set1_9, linewidth = 2)
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