# Portions of this code are modified from Convex.jl,
# which is available under an MIT license (see LICENSE).

using JuMP, DataFrames
using MathOptInterface
using Clarabel
using Distributed

const MOI = MathOptInterface

# main problem library is stored here 
PROBLEMS = Dict{String,Dict{String,Function}}()

#macro for bringing problems into PROBLEMS.   Taken from Convex.jl

macro add_problem(prefix, q)
    @assert prefix isa Symbol
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
            String($(Base.Meta.quot(prefix))),
            Dict{String,Function}(),
        )
        dict[String($(Base.Meta.quot(name)))] = $(esc(name))
    end
end

function run_benchmarks_inner(
    optimizer_factory;
    settings::Dict = Dict{Symbol,Any}(),
    verbose = true,
    exclude::Vector{Regex} = Regex[],
    include::Union{Nothing,Vector{String},Vector{Regex}} = Regex[],
    class::Union{Nothing,Vector{String},Vector{Regex}} = Regex[r".*"],
    time_limit::Float64 = Inf,
)
    groups = Dict{String,Dict}()
    for classkey in keys(PROBLEMS)

        # skip if class is not in class list or is excluded 
        if any(occursin.(exclude, Ref(classkey))) 
            continue
        elseif !any(occursin.(class, Ref(classkey))) 
            continue
        end   
            
        groups[classkey] = Dict()

        for test_name in keys(PROBLEMS[classkey])

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
                println("\n\nSolving : ", test_name,"\n")
            else
                println("Solving : ", test_name)
            end

            #solve and log results
            groups[classkey][test_name] = solve_with_timeout(time_limit,classkey,test_name,optimizer_factory,settings,verbose)

        end
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
    while true
        if pid ∉ workers()
            break 
        else 
            println("trying to kill pid = ", pid)
            try
                interrupt(pid)
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
        kill_worker(pid)
        #if solver failed, get a summary for a blank model
        solution = solution_summary(Model(optimizer_factory))
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
        model = Model(optimizer_factory)
        set_silent(model)
        try 
            test(model)
        catch
        end
    end
end 

function remote_solve(time_limit,classkey,test_name,optimizer_factory,settings,verbose)

    #create an empty model and pass to solver 
    model = Model(optimizer_factory)
        for (key,val) in settings 
            set_optimizer_attribute(model, string(key), val)
        end
    if(verbose == false); 
        set_silent(model); 
    else 
        unset_silent(model); 
    end
    
    #not all solver support setting time limits. Looking at you, ECOS.
    try
        set_time_limit_sec(model, time_limit)
    catch
    end

    ClarabelBenchmarks.PROBLEMS[classkey][test_name](model)

    return solution_summary(model)
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

function run_benchmarks!(df, solvers, class; exclude = Regex[], time_limit = Inf, verbose = false, tag = nothing, rerun = false)

    for package in solvers 

        #skip if already run for this solver with this particular tag
        if(!rerun && !isempty(df) && (String(Symbol(package)),tag) ∈ collect(zip(df.solver,df.tag)))
            println("Loading results for ", package)
            continue
        end 
        #delete any existing results if rerunning with this tag 
        if(rerun && !isempty(df)) 
            println("Rerunning results for ", package)
            idx = String(Symbol(package)) .== df.solver .&& tag .== df.tag
            df = df[.!idx,:] 
        end


        println("Solving with ", package)

        settings = ClarabelBenchmarks.SOLVER_CONFIG[Symbol(package)]
        result = ClarabelBenchmarks.run_benchmarks_inner(
            package.Optimizer; 
            settings = settings,
            class = class,
            verbose = verbose,
            exclude = exclude,
            time_limit = time_limit)

        result[!,:tag] .= tag

        result[!,:solver] .= String(Symbol(package))

        allowmissing!(result)
        df = [df;result]
    end

    sort!(df,[:group, :problem])
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

function bench_common(filename, solvers, class; exclude = Regex[], time_limit = Inf, 
        verbose = false, tag = nothing, rerun = false, plotlist = nothing, ok_status = nothing)
    
    (filedir,filename)  = splitdir(filename)
    (filename,_fileext) = splitext(filename)
    
    savefile = joinpath((filedir,"results",filename * ".jld2"))
    plotfile = joinpath((filedir,"results",filename * ".pdf"))

    if isfile(savefile)
        println("Loading benchmark data from: ", savefile)
        df = load(savefile)["df"]
        #if df doesn't already have a tag field, add it here 
        if "tag" ∉ names(df)
            df[!,:tag] .= nothing 
        end
    else 
        println("Saving benchmark data to: ", savefile)
        df = DataFrame()
    end

    df = run_benchmarks!(df, solvers, class; 
                    exclude = exclude, 
                    time_limit = time_limit, 
                    verbose = verbose, 
                    tag = tag,
                    rerun = rerun)

    jldsave(savefile; df)   

    h = performance_profile(df,plotlist=plotlist,ok_status=ok_status)
    savefig(h,plotfile)

    return df

end

