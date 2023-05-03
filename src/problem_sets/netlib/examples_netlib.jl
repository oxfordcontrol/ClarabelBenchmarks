function netlib_feasible_generic(
    model,
    netlib_feasible_problem
)
    (c, Aineq, bineq, Aeq, beq) = netlib_feasible_load(netlib_feasible_problem)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x))
    optimize!(model)

    return nothing

end

for test_name in netlib_feasible_get_test_names()
    fcn_name = Symbol("netlib_feasible_" * test_name)
    @eval begin
            @add_problem netlib_feasible function $fcn_name(
                model,
            )
                return netlib_feasible_generic(model,$test_name)
            end
    end
end 

function netlib_infeasible_generic(
    model,
    netlib_infeasible_problem
)
    (c, Aineq, bineq, Aeq, beq) = netlib_infeasible_load(netlib_infeasible_problem)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x))
    optimize!(model)

    return nothing

end

for test_name in netlib_infeasible_get_test_names()
    fcn_name = Symbol("netlib_infeasible_" * test_name)
    @eval begin
            @add_problem netlib_infeasible function $fcn_name(
                model,
            )
                return netlib_infeasible_generic(model,$test_name)
            end
    end
end 