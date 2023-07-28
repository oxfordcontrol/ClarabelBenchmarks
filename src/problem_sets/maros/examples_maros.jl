function maros_generic(
    model,
    maros_problem,
    shift = false
)
    (P, c, Aineq, bineq, Aeq, beq) = maros_load(maros_problem)

    if(shift)
        exp = -Inf
        origP = deepcopy(P)
        while true 
            try cholesky(P)
                println("Cholesky factorizability confirmed")
                if(exp != -Inf)
                    println("Diagonal shifted by 10^$exp")
                end
                break
            catch 
                if(exp == -Inf)
                    exp = -15
                else
                    exp += 1
                end
                P.nzval .= origP.nzval
                P += (10.)^(exp)*I
            end
        end 
    end

    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)
    optimize!(model)

    return nothing

end

#shifted versions 
for test_name in maros_get_test_names()

    fcn_name = Symbol("maros_shifted_" * test_name )
    @eval begin
            @add_problem maros_shifted function $fcn_name(
                model,
            )
                return maros_generic(model,$test_name,$true)
            end
    end
end 

#original versions 
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





