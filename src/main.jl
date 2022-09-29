# Portions of this code are modified from Convex.jl,
# which is available under an MIT license (see LICENSE).

using JuMP, DataFrames

# main problem library is stored here %PJG: Should be const
const PROBLEMS = Dict{String,Dict{String,Function}}()

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
    class::Union{Nothing,Vector{String},Vector{Regex}} = Regex[r".*"],
)
    groups = Dict{String,Dict}()
    for classkey in keys(PROBLEMS)

        # skip if class is not in class list 0or otherwise excluded 
        any(occursin.(exclude, Ref(classkey))) && continue
        any(occursin.(class,   Ref(classkey))) || continue

        groups[classkey] = Dict()
        for test_name in keys(PROBLEMS[classkey])

            #skip test level exclusions 
            any(occursin.(exclude, Ref(test_name))) && continue

            #create an empty model and pass to solver 
            model = Model(optimizer_factory; settings...)
            if(verbose == false); set_silent(model); end

            #tell me which problem I'm solving, even if not verbose 
            if(verbose)
                println("\n\nSolving : ", test_name,"\n")
            else
                println("Solving : ", test_name)
            end

            #solve and log results
            PROBLEMS[classkey][test_name](model)
            groups[classkey][test_name] = solution_summary(model)
        end
    end
    return groups
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

    println(typeof(dual_cost))
    println((dual_cost))

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





