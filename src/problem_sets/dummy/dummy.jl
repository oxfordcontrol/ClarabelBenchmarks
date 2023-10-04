# dummy problems for compiler warmup
using JuMP

@add_problem dummy qp function dummy_qp(
    model; kwargs...
)

    function build(model)
        @variable(model, x)
        @constraint(model, x >= 2)
        @objective(model, Min, x^2 + x)
    end

    solve_generic(build, model; kwargs...)
end

@add_problem dummy lp function dummy_lp(
    model; kwargs...
)

    function build(model)
        @variable(model, x)
        @constraint(model, x <= 2)
        @objective(model, Max, x)
    end

    solve_generic(build, model; kwargs...)
end

@add_problem dummy socp function dummy_socp(
    model; kwargs...
)

    function build(model)
        @variable(model, x[1:3])
        @constraint(model, x in SecondOrderCone())
        @objective(model, Min, x[1]^2 + x[2]^2 + x[1] + x[2])
    end

    solve_generic(build, model; kwargs...)
end

@add_problem dummy expcone function dummy_expcone(
    model; kwargs...
)

    function build(model)
        @variable(model, x[1:3])
        @constraint(model, x in MOI.ExponentialCone())
        @objective(model, Min, (x[1] + x[2])^2)
    end

    solve_generic(build, model; kwargs...)
end

@add_problem dummy powcone function dummy_powcone(
    model; kwargs...
)

    function build(model::GenericModel{T}) where {T}
        @variable(model, x[1:3])
        @constraint(model, x in MOI.PowerCone(T(0.5)))
        @objective(model, Min, (x[1] + x[2])^2)
    end

    solve_generic(build, model; kwargs...)
end

@add_problem dummy sdpcone function dummy_sdpcone(
    model; kwargs...
)

    function build(model)
        @variable(model, x[1:2,1:2])
        @constraint(model, x in PSDCone())
        @objective(model, Min, (x[1] + x[2] + x[3])^2)
    end 
    
    solve_generic(build, model; kwargs...)
end


@add_problem dummy mixed function dummy_mixedcone(
    model; kwargs...
)
    function build(model)
        @variable(model, x[1:2,1:2])
        @constraint(model, x in PSDCone())
        @constraint(model, x[:] in SecondOrderCone())
        @constraint(model, x[1] <= 2)
        @objective(model, Min, (x[1] + x[2] + x[3])^2 + x[1] + 2*x[2])
    end 

    solve_generic(build, model; kwargs...)
end


