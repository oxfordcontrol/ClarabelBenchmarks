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
    optimize!(model)

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
    optimize!(model)




    return nothing

end


# Lasso 
for test_name in sslsq_get_test_names()
    fcn_name = Symbol("sslsq_lasso_" * test_name)
    @eval begin
            @add_problem sslsq function $fcn_name(
                model,
            )
                return sslsq_lasso(model,$test_name)
            end
    end
end 

# Huber
for test_name in sslsq_get_test_names()
    fcn_name = Symbol("sslsq_huber_" * test_name)
    @eval begin
            @add_problem sslsq function $fcn_name(
                model,
            )
                return sslsq_huber(model,$test_name)
            end
    end
end 

