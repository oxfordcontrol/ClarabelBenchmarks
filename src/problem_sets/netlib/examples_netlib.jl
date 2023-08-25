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



for test_name in netlib_feasible_get_test_names()
    
    group_name = "netlib_feasible"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model,
            )
                return netlib_feasible_generic(model,$test_name)
            end
    end
end 


for test_name in netlib_infeasible_get_test_names()
    
    group_name = "netlib_infeasible"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model,
            )
                return netlib_infeasible_generic(model,$test_name)
            end
    end
end 

