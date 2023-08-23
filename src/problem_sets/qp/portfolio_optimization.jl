# Huber fitting.   Uses reformulation at https://osqp.org/docs/examples/portfolio.html

using Random

function portfolio_optimization(model, n, γ = 1)

    rng = Random.MersenneTwister(271324 + n)

    #problem dimensions wrt n
    p = 0.125
    k = ceil(Int,0.1 * n)
    density = 0.5

    F = sprandn(rng,n, k, density)
    d = rand(rng,n).*sqrt(k) 
    D = sparse(Diagonal(d))
    μ = randn(rng,n)

    @variable(model, x[1:n])
    @variable(model, y[1:k])
    @constraint(model, y .== F'*x)
    @constraint(model, sum(x) == 1.)
    @constraint(model, x .>= 0)
    @objective(model, Min, x'*D*x + y'*y - 1/(2γ) * (μ'*x))

    optimize!(model)

end


#generate problems according to problem type and size 

for n in [100, 1000, 5000]

    group_name = "qp"
    test_name  = "portfolio_optimization_n_" * string(n)
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model,
        )
            return portfolio_optimization(model,$n)
        end
    end
end




