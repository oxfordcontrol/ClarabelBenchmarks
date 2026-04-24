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

@add_problem dummy socp2 function dummy_socp2(
    model; kwargs...
)

    function build(model)
        @variable(model, x[1:3])
        @variable(model, y[1:3])
        @constraint(model, x in SecondOrderCone())
        @constraint(model, y in SecondOrderCone())
        @objective(model, Min, x[1]^2 + 2*x[2]^2 + 3*x[3]^2 + x[1] + x[2] + 4*y[1]^2 + 5*y[2]^2 + 6*y[3]^2 - y[1] + y[3])
    end

    solve_generic(build, model; kwargs...)
end

@add_problem dummy socp3 function dummy_socp3(
    model; kwargs...
)

    function build(model)
        @variable(model, x[1:5])
        @variable(model, y[1:5])
        @constraint(model, x in SecondOrderCone())
        @constraint(model, y in SecondOrderCone())
        @objective(model, Min, x[1]^2 + 2*x[2]^2 + 3*x[3]^2 + 2*x[4]^2 + x[5]^2+ x[1] + x[2] + 4*y[1]^2 + 5*y[2]^2 + 6*y[3]^2 + 5*y[4]^2 + 3*y[5]^2 - y[1] + y[3])
    end

    solve_generic(build, model; kwargs...)
end

@add_problem dummy socp4 function dummy_socp4(
    model; kwargs...
)

    function build(model)
        @variable(model, x[1:5])
        @constraint(model, x in SecondOrderCone())
        @objective(model, Min, x[1]^2 + 2*x[2]^2 + 3*x[3]^2 + 2*x[4]^2 + x[5]^2+ x[1] + x[2])
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


