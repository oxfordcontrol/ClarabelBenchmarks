# dummy problems for compiler warmip
using JuMP

@add_problem dummy function dummy_qp(
    model,
)

    @variable(model, x)
    @constraint(model, x >= 2)
    @objective(model, Min, x^2)
    optimize!(model)

    return nothing
end

@add_problem dummy function dummy_lp(
    model,
)

    @variable(model, x)
    @constraint(model, x <= 2)
    @objective(model, Max, x)
    optimize!(model)

    return nothing
end

@add_problem dummy function dummy_socp(
    model,
)

    @variable(model, x[1:3])
    @constraint(model, x in SecondOrderCone())
    @objective(model, Min, (x[1] + x[2])^2)
    optimize!(model)

    return nothing
end

@add_problem dummy function dummy_expcone(
    model,
)

    @variable(model, x[1:3])
    @constraint(model, x in MOI.ExponentialCone())
    @objective(model, Min, (x[1] + x[2])^2)
    optimize!(model)

    return nothing
end

@add_problem dummy function dummy_powcone(
    model,
)

    @variable(model, x[1:3])
    @constraint(model, x in MOI.PowerCone(0.5))
    @objective(model, Min, (x[1] + x[2])^2)
    optimize!(model)

    return nothing
end

