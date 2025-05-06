# Huber fitting.   Uses reformulation at https://osqp.org/docs/examples/huber.html

using Random

function huber_fitting(model::GenericModel{T}, n) where{T}

    rng = Random.MersenneTwister(271324 + n)

    p = T(0.125)
    m = round(Int,T(1.5) * n)

    A = sprandn(rng,T,m,n,0.125)

    x_true = randn(rng,T,n) / sqrt(n)
    ind95 = (rand(rng,T,m) .< T(0.95)).*one(T)
    b = A*x_true .+
        0.5*randn(rng,T,m).*ind95 .+
        T(10).*rand(rng,T,m).*(1. .- ind95)

    @variable(model, u[1:m])
    @variable(model, r[1:m])
    @variable(model, s[1:m])
    @variable(model, x[1:n])
    @constraint(model, r  .>= 0.)
    @constraint(model, s  .>= 0.)
    @constraint(model, A*x .- b .- u .== r .- s )
    @objective(model, Min, dot(u,u) + 2 * ones(T,m)'*(r + s))

end


#generate problems according to problem size 

for n in [10, 100, 500, 1000]

    group_name = "qp"
    test_name  = "huber_fitting_n_" * string(n)
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(huber_fitting,model,$n; kwargs...)
        end
    end
end




