# Huber fitting.   Uses reformulation at https://osqp.org/docs/examples/huber.html

using Random

function huber_fitting(model, n)

    rng = Random.MersenneTwister(271324 + n)

    p = 0.125
    m = round(Int,1.5 * n)

    A = sprandn(rng,m,n,0.125)

    x_true = randn(rng,n) / sqrt(n)
    ind95 = (rand(rng,m) .< 0.95).*1.
    b = A*x_true .+
        0.5*randn(rng,m).*ind95 .+
        (10.).*rand(rng,m).*(1. .- ind95)

    @variable(model, u[1:m])
    @variable(model, r[1:m])
    @variable(model, s[1:m])
    @variable(model, x[1:n])
    @constraint(model, r  .>= 0.)
    @constraint(model, s  .>= 0.)
    @constraint(model, A*x .- b .- u .== r .- s )
    @objective(model, Min, dot(u,u) + 2 * ones(m)'*(r + s))
    optimize!(model)

end


#generate problems according to problem size 

for n in [10, 100, 500, 1000]

    group_name = "qp"
    test_name  = "huber_fitting_n_" * string(n)
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model,
        )
            return huber_fitting(model,$n)
        end
    end
end




