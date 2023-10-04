using JuMP

function maros_generic(
    model::GenericModel{T},
    maros_problem,
    shift = false
) where {T}
    (P, c, Aineq, bineq, Aeq, beq) = maros_load(maros_problem)

    shift && (P = shift_P(P))

    #cast to T if needed, e.g. for BigFloat testing 
    P = T.(P)
    c = T.(c)
    Aineq = T.(Aineq)
    Aeq = T.(Aeq)
    bineq = T.(bineq)
    beq = T.(beq)

    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + T(1/2)*x'*P*x)

    return nothing

end

function shift_P(P) 

    thresh = 1e-3 
    s      = -16
        
    P = P + eps()*I  #force nonzero diagonal terms 
    origP = deepcopy(P)
    
    while true 
        issuccess(cholesky(P - thresh*I; check = false)) && break
        s += 1
        P.nzval .= origP.nzval
        P += ((10.)^s)*I
    end 
    P 
end 


#shifted versions 
for test_name in maros_get_test_names()

    group_name = "maros_shifted"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model; kwargs...
            )
            return solve_generic(maros_generic,model,$test_name,$true; kwargs...)
        end
    end
end 

#original versions 
for test_name in maros_get_test_names()
    
    group_name = "maros"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model; kwargs...
            )
                return solve_generic(maros_generic,model,$test_name,$false; kwargs...)
            end
    end
end 





