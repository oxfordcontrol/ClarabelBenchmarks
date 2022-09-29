# dummy problems for compiler warmip


@add_problem dummy function foo(
    model,
)

    @variable(model, x)
    @constraint(model, x >= 2)
    @objective(model, Min, x^2)
    optimize!(model)

    return nothing

end


@add_problem dummy function bar(
    model,
)

    @variable(model, x)
    @constraint(model, x <= 2)
    @objective(model, Min, x)
    optimize!(model)

    return nothing

end
