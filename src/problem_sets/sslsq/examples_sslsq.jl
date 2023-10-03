function sslsq_lasso(
    model,
    problem
)
    (A,b) = sslsq_load(problem)
    (m,n) = size(A)
    @assert(length(b) == m)
    
    λ = norm(A'*b,Inf)

    @variable(model, y[1:m])
    @variable(model, t[1:n])
    @variable(model, x[1:n])
    @constraint(model,  x .<= t)
    @constraint(model, -t .<= x)
    @constraint(model, y .== A*x - b)
    @objective(model, Min, y'*y + λ*sum(t))

    return nothing

end

function sslsq_huber(
    model,
    problem
)
    (A,b) = sslsq_load(problem)
    (m,n) = size(A)
    M = 1
    @variable(model, x[1:n])
    @variable(model, u[1:m])
    @variable(model, r[1:m])
    @variable(model, s[1:m])
    @constraint(model,  r .>= 0)
    @constraint(model,  s .>= 0)
    @constraint(model, A*x - b - u .== r - s )
    @objective(model, Min, u'*u + 2*M*sum(r+s))

    return nothing

end


# Lasso 
for matrix_name in sslsq_get_test_names()
    
    group_name = "sslsq"
    test_name  = matrix_name * "_lasso"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model; kwargs...
            )
                return solve_generic(sslsq_lasso,model,$matrix_name; kwargs...)
            end
    end
end 

# Huber
for matrix_name in sslsq_get_test_names()

    group_name = "sslsq"
    test_name  = matrix_name * "_huber"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model; kwargs...
            )
                return solve_generic(sslsq_huber,model,$matrix_name; kwargs...)
            end
    end
end 

