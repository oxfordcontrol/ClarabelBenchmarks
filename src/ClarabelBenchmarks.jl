module ClarabelBenchmarks

    # main test function and problem def macros live here 
    include("./tools.jl")

    #benchmark standard settings for each solver type
    include("./benchmarks/solver_config.jl")

    #fake problems for compiler warmup 
    include("./problem_sets/dummy/dummy.jl")

    #add new categories and problems here
    include("./problem_sets/maros/include.jl")
    include("./problem_sets/netlib/include.jl")
    include("./problem_sets/cblib/include.jl")
    include("./problem_sets/lp/include.jl")
    include("./problem_sets/qp/include.jl")
    include("./problem_sets/socp/include.jl")
    include("./problem_sets/sos/include.jl")
    include("./problem_sets/pow/include.jl")
    include("./problem_sets/sslsq/include.jl")
    include("./problem_sets/mpc/include.jl")
    include("./problem_sets/opf/include.jl")
    include("./problem_sets/hard_socp/include.jl")
    include("./problem_sets/sdplib/include.jl")

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
