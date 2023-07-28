function maros_generic(
    model,
    maros_problem,
    shift = false
)
    (P, c, Aineq, bineq, Aeq, beq) = maros_load(maros_problem)

    if(shift)
        P = Matrix(P)
        while true 
            try cholesky(P)
                break
            catch 
                #apply shift to P to eliminate 
                #slightly negative eigenvalues
                P = Matrix(P)
                e = eigen(P)
                c = minimum(e)
                c = c < 0. ? c : 0.
                P = sparse(P + (2*(-c + eps()*maximum(e))*I))
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

for test_name in maros_get_test_names()

    #shifted versions 
    fcn_name = Symbol("maros_shifted_" * test_name)
    @eval begin
            @add_problem maros function $fcn_name(
                model,
            )
                return maros_generic(model,$test_name,true)
            end
    end
end 


for test_name in maros_get_test_names()

    #original versions 
    fcn_name = Symbol("maros_" * test_name)
    @eval begin
            @add_problem maros_shifted function $fcn_name(
                model,
            )
                return maros_generic(model,$test_name)
            end
    end
end 





