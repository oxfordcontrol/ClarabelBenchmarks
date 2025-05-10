module ClarabelBenchmarks

    # main test function and problem def macros live here 
    include("./tools.jl")

    #benchmark standard settings for each solver type
    include("./benchmarks/solver_config.jl")


    #look in problem_sets for directories with include.jl files
    problem_sets_dir = joinpath(@__DIR__, "problem_sets")
    for dir in readdir(problem_sets_dir)
        println("including problem set: ", dir)
        include_file = joinpath(problem_sets_dir, dir, "include.jl")
        if isdir(joinpath(problem_sets_dir, dir)) && isfile(include_file)
            include(include_file)
        end
    end

    # hard socps are handled separately since they are defined 
    # by gathering up a subset of problems defined above 
    #include("./problem_sets/hard_socp/include_hard_socp.jl")

    #plotting functions 
    include("./performance_profile.jl")


    #Global Gurobi license reference to support test on 
    #machines with a fixed number of licenses 
    const GRB_ENV_REF = Ref{Gurobi.Env}()

    function __init__()
        global GRB_ENV_REF
        GRB_ENV_REF[] = Gurobi.Env()
        return
    end

    #Additional solver configurations can be made to look like
    #standalone solvers, e.g. a 128 bit version of Clarabel
    #commented out but left for future reference
    # module Clarabel128
    #     using Clarabel, MultiFloats
    #     Optimizer = Clarabel.Optimizer{Float64x2}
    # end

    #identical solver with different name.   Useful
    #for benchmarking if configured with use_quad_obj = false
    module ClarabelHSDE
        using Clarabel
        Optimizer = Clarabel.Optimizer
    end
    export ClarabelHSDE

    #identical solver with different name.   Useful
    #for benchmarking if configured with use_quad_obj = false
    module ClarabelRsHSDE
        using ClarabelRs
        Optimizer = ClarabelRs.Optimizer
    end
    export ClarabelRsHSDE
end
