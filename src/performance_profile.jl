using Plots, JLD2,DataFrames

function performance_profile(df)

    best     = Dict()
    problems = unique(df.problem)
    tagged_solvers_all = collect(zip(df.solver,df.tag))
    tagged_solvers_unique  = unique(tagged_solvers_all)
    tagged_solvers_unique = sort(tagged_solvers_unique, by = (x) -> x[1])

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
    for tagged_solver in tagged_solvers_unique

        #cleanup solver strings 
        solverstr = tagged_solver[1]
        solvertag = tagged_solver[2]
        solverstr = solverstr == "Clarabel"   ? "Clarabel (Julia)" : solverstr
        solverstr = solverstr == "ClarabelRs" ? "Clarabel (Rust)"  : solverstr

        if !isnothing(solvertag)
            solverstr = solverstr * " : " * string(solvertag) 
        end

        t = pp[pp.solver .== tagged_solver[1] .&& pp.tag .== tagged_solver[2], :].pratio
        y = [sum(t .< p)/n for p in perf_levels]
        plot!(h, perf_levels,y,label = solverstr, palette = :tol_bright, linewidth = 2)
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