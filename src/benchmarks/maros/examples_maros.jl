function maros_generic(
    model,
    maros_problem
)
    (P, c, Aeq, beq, Aineq, bineq) = maros_load(maros_problem)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)
    optimize!(model)

    return nothing

end

for test_name in maros_get_test_names()
    fcn_name = Symbol("maros_" * test_name)
    @eval begin
            @add_problem maros function $fcn_name(
                model,
            )
                return maros_generic(model,$test_name)
            end
    end
end 



