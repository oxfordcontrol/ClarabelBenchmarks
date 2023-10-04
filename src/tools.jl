# Portions of this code are modified from Convex.jl,
# which is available under an MIT license (see LICENSE).

using JuMP, DataFrames, MathOptInterface
using MathOptInterface
using Clarabel
using Distributed
using PrettyTables, Printf

const MOI = MathOptInterface

# main problem library is stored here 
PROBLEMS = Dict{String,Dict{String,Function}}()

#macro for bringing problems into PROBLEMS.   Modified from Convex.jl

macro add_problem(group_name, test_name, q)
    group_name = Symbol(group_name)
    test_name  = Symbol(test_name)
    @assert test_name isa Symbol
    if q.head == :block
        f = q.args[2]
    elseif q.head == :function
        f = q
    else
        error("head $(q.head) unexpected")
    end
    name = f.args[1].args[1]
    if name isa Expr
        name = name.args[1]
    end
    return quote
        $(esc(f))
        dict = get!(
            PROBLEMS,
            String($(Base.Meta.quot(group_name))),
            Dict{String,Function}(),
        )
        dict[String($(Base.Meta.quot(test_name)))] = $(esc(name))
    end
end

function solve_generic(fcn, model, args...; solve = true)

    if !isa(model, GenericModel) 
        model = get_typed_model(model)  #convert to JuMP object
    end

    fcn(model, args...)

    if solve
        optimize!(model)
    else 
        #try to manually populate the solver model 
        #without actually calling it 
        MOI.Utilities.attach_optimizer(model)
        JuMP.MOI.copy_to(
            model.moi_backend.optimizer.model.optimizer,
            model.moi_backend.optimizer.model
        )
    end
    return model
end


function run_benchmarks_inner(
    optimizer_factory, 
    classkey::String;
    settings::Dict = Dict{Symbol,Any}(),
    verbose = true,
    exclude::Vector{Regex} = Regex[],
    include::Union{Nothing,Vector{String},Vector{Regex}} = Regex[],
    time_limit::Float64 = Inf,
)
    groups = Dict{String,Dict}()

    groups[classkey] = Dict()

    ntests = length(keys(PROBLEMS[classkey]))
    
    for (i,test_name) in enumerate(keys(PROBLEMS[classkey]))

        #skip test level exclusions 
        any(occursin.(exclude, Ref(test_name))) && continue

        #skip if an explicit include list is provided and 
        #this test is not a match 
        if !isempty(include) 
            if(isa(include,Vector{String}))
                !any(in(test_name, include)) && continue
            else
                !any(occursin.(include, Ref(test_name))) && continue
            end
        end

        #tell me which problem I'm solving, even if not verbose 
        if(verbose)
            println("\n\nSolving : ", test_name," [", i, "/", ntests, "]","\n")
        else
            println("Solving : ", test_name, " [", i, "/", ntests, "]")
        end

        #solve and log results
        groups[classkey][test_name] = solve_with_timeout(time_limit,classkey,test_name,optimizer_factory,settings,verbose)

	#flush messages - useful when HPC logging
	flush(Base.stdout)
	flush(Base.stderr)

    end

    return post_process_benchmarks(groups)
end

function any_workers()
    workers() != [1]
end 

function initialize_worker()
    #reinitialize worker
    newpid = addprocs(1)    
    println("initialized new worker.  pid = ", newpid) 
end 

function kill_worker(pid)

    kill_attempts = 0
    while true
        kill_attempts += 1 
        if pid ∉ workers()
            break 
        else 
            println("trying to kill pid = ", pid)
            try
                if kill_attempts < 100
                    interrupt(pid)
                else 
                    println("killing pid ", pid, " via rmprocs")
                    rmprocs(pid)
                end
            catch
            end
        end
        sleep(0.1)
    end 
end 

function wait_for_task(task, timeout)

    tstart = time()
    while true 
        if istaskdone(task) && !istaskfailed(task)
            println("task finished successfully")
            return true 
        elseif time() - tstart > timeout
            println("task timed out")
            return false 
        elseif istaskfailed(task)
            println("task failed")
            return false 
        end 
        sleep(0.1)
    end 
end 

function solve_with_timeout(time_limit,classkey,test_name,optimizer_factory,settings,verbose)

    if !any_workers() 
        #reinitialize worker
        initialize_worker()
    end 
    
    pid = workers()[end]

    #force reload modules and precompile 
    remote_package_reload(Symbol(solver_module(optimizer_factory)))
    remote_solve_dummies(optimizer_factory)

    #solve our actual problem on the remote
    ch  = RemoteChannel(pid)

    task = @async put!(ch,remotecall_fetch(remote_solve, pid,time_limit,classkey,test_name,optimizer_factory,settings,verbose))

    timeout = time_limit + 10 #allow time for JuMP processing

    if wait_for_task(task,timeout)
        solution = take!(ch)
    else 
        println("remote solve failed or timed out")
        #kill if still running 
        if(!istaskdone(task))
            kill_worker(pid)
        end
        #if solver failed, get a summary for a blank model
        solution = solution_summary(get_typed_model(optimizer_factory))
    end 
    finalize(ch)
    return solution 
end

function solver_module(optimizer_factory)
    return Base.moduleroot(methods(optimizer_factory)[1].module)

end

function remote_package_reload(optimizer_symbol)

    println("calling remote_package_reload with ", optimizer_symbol)

    eval(quote @everywhere using ClarabelBenchmarks end)
    eval(quote @everywhere using JuMP end)

    eval(quote @everywhere using $optimizer_symbol end)

end

function remote_solve_dummies(optimizer_factory)

    println("calling remote_solve_dummies with ", optimizer_factory)
    expr = quote ClarabelBenchmarks.run_dummy_problems_inner($optimizer_factory) end 
    eval(quote @everywhere $expr end)
end

function run_dummy_problems_inner(optimizer_factory)

    if myid() == 1
        return
    end

    println("solving dummies on pid = ", myid())
    for test = values(ClarabelBenchmarks.PROBLEMS["dummy"])
        #try to solve.   If it fails, just move on
        #since we're just trying to force compilation.
        #note solvers will fail on these problems if they 
        #don't support the necessary cone types
        model = get_typed_model(optimizer_factory)
        set_silent(model)
        try 
            test(model)
        catch
        end
    end
end 

function remote_solve(time_limit,classkey,test_name,optimizer_factory,settings,verbose)

    #create an empty model and pass to solver 
    println("calling remote solve")
    model = get_typed_model(optimizer_factory)

    if(verbose == false); 
        set_silent(model); 
    else 
        unset_silent(model); 
    end
    
    for (key,val) in settings 
        set_optimizer_attribute(model, string(key), val)
    end
    
    #not all solver support setting time limits. Looking at you, ECOS.
    try
        set_time_limit_sec(model, time_limit)
    catch
    end

    try
        ClarabelBenchmarks.PROBLEMS[classkey][test_name](model)
    catch e
        println(e)
    end
    println("solve success")

    return solution_summary(model)
end


function get_typed_model(optimizer_factory)

    # we want to allow for an optimizer_factory that produces non Float64 Clarabel solvers, 
    # which in turn require direct use of JuMP GenericModels.   Handle this case separately 
    # Some care is required though because Mosek.Optimizer is a function called "Optimizer", 
    # instead of a subtype of AbstractOptimizer.  The equivalent Mosek subtype is 
    # MosekTools.Optimizer, which probably should have been used everywhere instead.  

    if !isa(optimizer_factory,Function)
        if optimizer_factory <: Clarabel.Optimizer 
            #check what type it produces 
            T = collect(typeof(optimizer_factory()).parameters)[1]
            if T != Float64
                return GenericModel{T}(optimizer_factory)
            end
        end 
    end

    return Model(optimizer_factory)
end



function post_process_benchmarks(groups)
    df = DataFrame()
    for (group,results) in groups 

        isempty(results) && continue

        newdf = post_process_results_group(results)
        newdf[!,"group"] = repeat([group],size(newdf)[1])

        df = [df; newdf]
    end
    return df
end


function post_process_results_group(group)

    #turn a single group from the benchmarks into a DataFrame

    #flatten keys and solutions
    problems  = [k for k in keys(group)]
    solutions = [v for v in values(group)]

    #flatten solutions 
    solver      = map(s->s.solver            , solutions)
    solve_time  = map(s->s.solve_time        , solutions)
    iterations  = map(s->s.barrier_iterations, solutions)
    status      = map(s->string(s.termination_status), solutions)
    primal_cost =  map(s->s.objective_value, solutions)
    dual_cost   =  map(s->s.dual_objective_value, solutions)

    df = DataFrame(
       "problem" => problems, 
       "solver" => solver, 
       "solve_time" => solve_time,
       "iterations" => iterations,
       "status" => status,
       "primal_cost" => primal_cost, 
       "dual_cost" => dual_cost,
    )

    return df

end


function dropinfs(A,b; thresh = 5e19)

    b = b[:]
    finidx = abs.(b) .< thresh
    b = b[finidx]
    A = A[finidx,:]
    return A,b

end

function get_problem_data(group,name)

    #a roundabout way of accessing problem data...

    model = Model(Clarabel.Optimizer)
    set_optimizer_attributes(model,
                    "verbose"=>true,
                    "equilibrate_enable"=>false,
                    "max_iter"=>0,
                    "presolve_enable"=>false)
    ClarabelBenchmarks.PROBLEMS[group][name](model)

    solver = model.moi_backend.optimizer.model.optimizer.solver 

    P = solver.data.P 
    q = solver.data.q 
    A = solver.data.A 
    b = solver.data.b 

    #PJG: This will break once presolver is updated
    cone_specs = solver.data.presolver.cone_specs

    return (P,q,A,b,cone_specs)

end

# target directory for results.   
function get_path_results()

    path = mkpath(joinpath(@__DIR__,"../results"))

    return path
end

# target directory for jld2 data.  
function get_path_results_jld2()

    path = mkpath(joinpath(get_path_results(),"jld2"))

    # if this environment variable is set (e.g. via ARC/HPC), then
    # write into this subdirectory instead
    if(haskey(ENV,"BENCHMARK_RESULTS_OUTPUTDIR"))
	path = mkpath(joinpath(path,ENV["BENCHMARK_RESULTS_OUTPUTDIR"]))
    end

    return path
end

# target directory for plots.  
function get_path_results_plots()
    mkpath(joinpath(get_path_results(),"plots"))
end

# target directory for plots.  
function get_path_results_tables()
    mkpath(joinpath(get_path_results(),"tables"))
end


function run_benchmark!(package, classkey; exclude = Regex[], time_limit = Inf, verbose = false, tag = nothing, rerun = false)

    filename = "bench_" * classkey * "_" * String(Symbol(package)) * ".jld2"
    savefile = joinpath(get_path_results_jld2(),filename)

    #gather some basic system information
    cpu_model = Sys.cpu_info()[1].model
    host_name = gethostname()
    solver_config = ClarabelBenchmarks.SOLVER_CONFIG


    if isfile(savefile)
        println("Loading benchmark data from: ", savefile)
        try
            df = load(savefile)["df"]
            #if df doesn't already have a tag field, add it here 
            if "tag" ∉ names(df)
                df[!,:tag] .= nothing 
            end
        catch
            println("Error loading file, starting new data frame")
            df = DataFrame()
        end
    else 
            println("Saving benchmark data to new file: ", savefile)
        df = DataFrame()
    end


    #skip if already run for this solver with this particular tag
    if(!rerun && !isempty(df) && (String(Symbol(package)),tag) ∈ collect(zip(df.solver,df.tag)))
        println("Found existing results for ", package)
        return df
    end 
    #delete any existing results if rerunning with this tag 
    if(rerun && !isempty(df)) 
        println("Will rerun results for ", package)
        idx = String(Symbol(package)) .== df.solver .&& tag .== df.tag
        df = df[.!idx,:] 
    end

    println("Solving with ", package)

    settings = ClarabelBenchmarks.SOLVER_CONFIG[Symbol(package)]
    result = ClarabelBenchmarks.run_benchmarks_inner(
        package.Optimizer, classkey; 
        settings = settings,
        verbose = verbose,
        exclude = exclude,
        time_limit = time_limit)

    result[!,:tag] .= tag

    result[!,:solver] .= String(Symbol(package))

    allowmissing!(result)
    df = [df;result]
    df = sort!(df,[:group, :problem])

    println("Saving...")
    jldsave(savefile; df, cpu_model, host_name, solver_config)   

    return df
  
end


function benchmark(packages, classkey; exclude = Regex[], time_limit = Inf, 
        verbose = false, tag = nothing, rerun = false, plotlist = nothing, ok_status = nothing)
    
    df = DataFrame()

    println(packages)

    for package in packages 

        result = run_benchmark!(package, classkey; 
                        exclude = exclude, 
                        time_limit = time_limit, 
                        verbose = verbose, 
                        tag = tag,
                        rerun = rerun)

        allowmissing!(result)
        df = [df;result]

    end 

    #performance profile 
    filename = "bench_" * classkey * "_performance.pdf"
    h = performance_profile(df,plotlist = plotlist, ok_status = ok_status)
    plotfile = joinpath(get_path_results_plots(),filename)
    savefig(h,plotfile)

    #time profile 
    filename = "bench_" * classkey * "_time.pdf"
    h = time_profile(df,plotlist = plotlist, ok_status = ok_status)
    plotfile = joinpath(get_path_results_plots(),filename)
    savefig(h,plotfile)

    #shifted means as a latex table  
    filename = "bench_" * classkey * "_sgm.tex"
    filename = joinpath(get_path_results_tables(),filename)
    out = shifted_geometric_means(df, plotlist = plotlist, ok_status = ok_status)
    write_sgm_table_file(filename,out)


    #tabulated results data 
    filename = "bench_" * classkey * "_detail_table.tex"
    filename = joinpath(get_path_results_tables(),filename)
    tables = build_results_tables(df)
    write_results_tables(tables,filename)


    return df

end

function write_sgm_table_file(filename,out)


    table = hcat(out[:,1],out)  #adds extra leading column
    data = out[1:end,2:end]
    headers = ["","",names(out)[2:end]...]  #drops "solvers"
    alignment = [:l,:l,fill(:c,length(headers)-2)...]

    #now we have 2 leading columns, with 4 rows.  
    #Give them custom strings
    table[:,1] = ["Shifted GM","","Failure Rate (%)",""]
    table[:,2] = ["Full Acc.","Low Acc.","Full Acc.","Low Acc."]

    io = open(filename, "w");
    pretty_table(io, table,header = headers, alignment = alignment, backend = Val(:latex))

    close(io)

end

function build_results_tables(df)

    problems = unique(df.problem)
    solvers = unique(df.solver)
    group = unique(df.group)[1]

    #remove problems that are not in the current benchmark set 
    #this will weed out some other results that were disabled
    #due to slow computation times and hence not solved in all configs 
    keepidx = df.problem .∈ [collect(keys(ClarabelBenchmarks.PROBLEMS[group]))]
    df = df[keepidx,:]
    problems = unique(df.problem)

    println(length(problems), " remaining...")

    solvers = sort(intersect(solvers,["ClarabelRs","ECOS","Mosek"]))

    # insert columns for each solver, for iterations, time / iteration / total time
    tables = Dict()
    for format in [:iterations => Int, :iter_time => Float64, :total_time=>Float64]
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
        is_ok      = df[df.problem .== problem .&& df.solver .== solver,:status][1] .== "OPTIMAL"

        if(is_ok)
            
            iter_time = iters > 0 ? total_time / iters : 0.0 

            tables[:iterations][i,solver] = iters
            tables[:iter_time][i,solver] = iter_time
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

function write_results_tables(tables,filename)


    #sort by size?
    perm =  sortperm(tables[:dims].n + tables[:dims].m)
    for key in keys(tables)
        tables[key] = tables[key][perm,:]
    end

    solvers = String.(names(tables[:iterations]))[2:end]
    problems = String.(tables[:iterations][:,1])

    io = open(filename, "w");

    println(io,"\\scriptsize")

    println(io,"\\begin{longtable}" * "{l" * "cccc" * "||ccc"^(length(solvers)) * "||}")

    println(io,"\\caption{\\detailtablecaption}")
    println(io,"\\\\")

    #print primary headerss
    print(io, " & &  & & ");
    for label in ["iterations","time per iteration(s)", "total time (s)"]
        print(io,"& \\multicolumn{3}{c||}{\\underline{$label}}");
    end 
    print(io, "\\\\[2ex] \n")

    #print secondary headers
    print(io, "Problem & vars. & cons. & nnz(A) & nnz(P) ");
    for i = 1:3
        for solver in solvers 
            print(io," & $solver");
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

        #time / iter 
        for solver in solvers 
            iter       = tables[:iterations][i,solver]
            iter_time  = tables[:iter_time][i,solver]

            #is this the best one in the row?
            if isequal(iter_time, minimum(skipmissing(tables[:iter_time][i,2:end])))
                iter_time_tag = best
            else 
                iter_time_tag = ""
            end

            if(ismissing(iter))
                iter_time = "-"
            else 
                iter_time = @sprintf("%4.3g",iter_time)
            end

            print(io, " &  $iter_time_tag $iter_time")
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

