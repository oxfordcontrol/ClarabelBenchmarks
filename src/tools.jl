# Portions of this code are modified from Convex.jl,
# which is available under an MIT license (see LICENSE).

using JuMP, DataFrames
using MathOptInterface
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


function run_benchmarks(
    optimizer_factory;
    settings::Dict = Dict{Symbol,Any}(),
    verbose = true,
    exclude::Vector{Regex} = Regex[],
    include::Union{Nothing,Vector{String},Vector{Regex}} = Regex[],
    class::Union{Nothing,Vector{String},Vector{Regex}} = Regex[r".*"],
    precompile::Bool = true,
)

    #run all of the dummy problems to force compilation
    if precompile
        run_dummy_problems(optimizer_factory)
    end

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

            #create an empty model and pass to solver 
            model = Model(optimizer_factory)
            for (key,val) in settings 
                set_optimizer_attribute(model, string(key), val)
            end
            if(verbose == false); set_silent(model); end

            #solve and log results
            try
                PROBLEMS[classkey][test_name](model)
                groups[classkey][test_name] = solution_summary(model)
            catch
                groups[classkey][test_name] = solution_summary(Model(optimizer_factory))
            end
        end
    end
    return post_process_benchmarks(groups)
end

function run_dummy_problems(optimizer_factory)

    for test = values(ClarabelBenchmarks.PROBLEMS["dummy"])
        #try to solve.   If it fails, just move on
        #since we're just trying to force compilation
        model = Model(optimizer_factory)
        set_silent(model)
        try 
            test(model)
        catch; 
        end
    end
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


