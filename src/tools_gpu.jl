# Portions of this code are modified from Convex.jl,
# which is available under an MIT license (see LICENSE).

using JuMP, DataFrames
using MathOptInterface
using Clarabel
using Distributed
using PrettyTables, Printf
using Gurobi

const MOI = MathOptInterface

function benchmark_gpu(packages, classkey; exclude = Regex[], time_limit = Inf, 
        verbose = false, tag = nothing, rerun = false, plotlist = nothing, ok_status = nothing, machine = :local, gpu_test = false)
    
    df = DataFrame()

    println(packages)

    for package in packages 

        result = run_benchmark!(package, classkey; 
                        exclude = exclude, 
                        time_limit = time_limit, 
                        verbose = verbose, 
                        tag = tag,
                        rerun = rerun,
                        machine = machine,
                        gpu_test = gpu_test)

        allowmissing!(result)
        df = [df;result]

    end 

    device = gpu_test ? "gpu_" : ""
    #performance profile 
    filename = "bench_" * device * classkey * "_performance.pdf"
    h = performance_profile(df,plotlist = plotlist, ok_status = ok_status)
    plotfile = joinpath(get_path_results_plots(),filename)
    savefig(h,plotfile)

    #time profile 
    filename = "bench_" * device * classkey * "_time.pdf"
    h = time_profile(df,plotlist = plotlist, ok_status = ok_status)
    plotfile = joinpath(get_path_results_plots(),filename)
    savefig(h,plotfile)

    #shifted means as a latex table  
    filename = "bench_" * device * classkey * "_sgm.tex"
    filename = joinpath(get_path_results_tables(),filename)
    out = shifted_geometric_means(df, plotlist = plotlist, ok_status = ok_status)
    write_sgm_table_file(filename,out; gpu_test=gpu_test)


    #tabulated results data 
    filename = "bench_" * device * classkey * "_detail_table.tex"
    filename = joinpath(get_path_results_tables(),filename)
    tables = build_results_tables_gpu(df, ok_status = ok_status)
    write_results_tables_gpu(tables,filename; gpu_test=gpu_test)

    return df

end

function build_results_tables_gpu(df; ok_status = nothing)

    problems = unique(df.problem)
    solvers = unique(df.solver)
    group = unique(df.group)[1]

    if(isnothing(ok_status))
        ok_status = ["OPTIMAL"]
    end

    #remove problems that are not in the current benchmark set 
    #this will weed out some other results that were disabled
    #due to slow computation times and hence not solved in all configs 
    keepidx = df.problem .∈ [collect(keys(ClarabelBenchmarks.PROBLEMS[group]))]
    df = df[keepidx,:]
    problems = unique(df.problem)

    println(length(problems), " remaining...")

    solvers = sort(intersect(solvers,["ClarabelBenchmarks.ClarabelGPU","ClarabelRs","ECOS","Mosek","Gurobi","ClarabelBenchmarks.MosekWithPresolve"]))

    # insert columns for each solver, for iterations, time / iteration / total time
    tables = Dict()
    for format in [:iterations => Int, :total_time=>Float64]
        #make a new table with solvers as the columns, and problems as the rows
        tables[format[1]] = DataFrame()
        insertcols!(tables[format[1]],  "" => problems)
        for solver in solvers 
            insertcols!(tables[format[1]],  solver => missings(format[2],length(problems)))
        end 
    end 

    #get the problem dimensions 
    tables[:dims] = DataFrame()
    insertcols!(tables[:dims],  "" => problems)
    insertcols!(tables[:dims],  :m => missings(Int,length(problems)))
    insertcols!(tables[:dims],  :n => missings(Int,length(problems)))
    insertcols!(tables[:dims],  :nnzP => missings(Int,length(problems)))
    insertcols!(tables[:dims],  :nnzA => missings(Int,length(problems)))


    #table of problem dimensions
    for (i,problem) in enumerate(problems)
        println("getting dimensions for " * problem)
        model = ClarabelBenchmarks.PROBLEMS[group][problem](Clarabel.Optimizer; solve = false)
        solver = model.moi_backend.optimizer.model.optimizer.solver
        data = solver.data
        tables[:dims][i,:m] = data.m 
        tables[:dims][i,:n] = data.n
        tables[:dims][i,:nnzA] = nnz(data.A)
        tables[:dims][i,:nnzP] = nnz(data.P)
    end 

    # statistics for each solver / problem pair
    for (i,problem) in enumerate(problems), solver in solvers 

        iters      = df[df.problem .== problem .&& df.solver .== solver,:iterations][1]
        total_time = df[df.problem .== problem .&& df.solver .== solver,:solve_time][1]
        is_ok      = df[df.problem .== problem .&& df.solver .== solver,:status][1] ∈ ok_status

        if(is_ok)

            tables[:iterations][i,solver] = iters
            tables[:total_time][i,solver] = total_time

        end
    end

    #eliminate any unsolveable problems 
    problems = tables[:iterations][:,1]
    goodrows = trues(length(problems))
    for (i,problem) in enumerate(problems)
        if all(ismissing.(collect(tables[:total_time][i,2:end])))
            goodrows[i] = false
        end
    end
    for key in keys(tables)
        tables[key] = tables[key][goodrows,:]
    end

    return tables

end 

function write_results_tables_gpu(tables,filename;gpu_test=false)


    #sort by size?
    perm =  sortperm(tables[:dims].n + tables[:dims].m)
    for key in keys(tables)
        tables[key] = tables[key][perm,:]
    end

    solvers = String.(names(tables[:iterations]))[2:end]
    problems = String.(tables[:iterations][:,1])

    io = open(filename, "w");

    println(io,"\\scriptsize")

    println(io,"\\begin{longtable}" * "{||l" * "cccc" * "||ccc"^(length(solvers)) * "||}")

    println(io,"\\caption{\\detailtablecaption}")
    println(io,"\\\\")

    #print primary headerss
    print(io, " & &  & & ");
    for label in ["iterations", "total time (s)"]
        print(io,"& \\multicolumn{3}{c||}{\\underline{$label}}");
    end 
    print(io, "\\\\[2ex] \n")

    #print secondary headers
    print(io, "Problem & vars. & cons. & nnz(A) & nnz(P) ");
    for i = 1:2
        for solver in solvers 
            if solver == "ClarabelBenchmarks.ClarabelGPU" && gpu_test
                print(io," & ClarabelGPU");
            elseif solver == "ClarabelBenchmarks.MosekWithPresolve" && gpu_test
                print(io," & Mosek*");
            else
                print(io," & $solver");
            end
        end 
    end
    print(io, "\\\\[1ex]\n")
    
    println(io,"\\hline")
    println(io,"\\endhead")

    for (i,problem) in enumerate(problems)

        problem = replace(problem,"_" => raw"\_")
        print(io, "\\sc{" * problem * "}")
        print(io, " & ", tables[:dims][i,:m])
        print(io, " & ", tables[:dims][i,:n])
        print(io, " & ", tables[:dims][i,:nnzA])
        print(io, " & ", tables[:dims][i,:nnzP])

        best = "\\winner "

        #iterations 
        for solver in solvers 
            iter       = tables[:iterations][i,solver]

            #is this the best one in the row?
            if isequal(iter, minimum(skipmissing(tables[:iterations][i,2:end])))
                iter_tag = best
            else 
                iter_tag = ""
            end

            if(ismissing(iter))
                iter = "-"
            else 
                iter = @sprintf("%d",iter)
            end

            print(io, " &  $iter_tag $iter")
        end 

        #total time 
        for solver in solvers 
            iter       = tables[:iterations][i,solver]
            total_time = tables[:total_time][i,solver]

            #is this the best one in the row?
            if isequal(total_time, minimum(skipmissing(tables[:total_time][i,2:end])))
                total_time_tag = best
            else 
                total_time_tag = ""
            end

            if(ismissing(iter))
                total_time = "-"
            else 
                total_time = @sprintf("%4.3g",total_time)
            end

            print(io, " &  $total_time_tag $total_time")
        end 
        print(io, "\\\\ \n")

    end 


    println(io,"\\end{longtable}")

    close(io)

end

