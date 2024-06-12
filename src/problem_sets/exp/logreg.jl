using LinearAlgebra, SparseArrays, Random
using Clarabel
using JuMP

"""
Logistic Regression problem from A.5 in POGS paper.
https://web.stanford.edu/~boyd/papers/pdf/pogs.pdf

Conic formulation from JuMP example:
https://jump.dev/JuMP.jl/stable/tutorials/conic/logistic_regression/
"""

function logreg_fit(model::GenericModel{T}, n) where{T}

    # Pick m > n (can change this later) TODO
    m = round(Int, 5 * n)

    rng = Random.MersenneTwister(40701)

    A = sprandn(rng, T, m, n, 0.125)

    # Generate v_i = 0 with probability 0.5, N(0, 1/n) otherwise
    v = T.(rand(rng, T, n) .< T(0.5))
    v .*= randn(rng, T, n) * sqrt(T(n))

    # Generate b_i = 0 with probability 1/(1 + exp(-v_i^T A_i)), 1 otherwise
    b = T.(rand(rng, T, m) .< (T(1) ./ (T(1) .+ exp.(-A * v))))

    # Pick lambda according to POGS paper
    λ = maximum(abs.(A'*(ones(m) * T(0.5) - b)))

    # Formulation from JuMP
    @variable(model, θ[1:n])
    @variable(model, t[1:m])

    for i in 1:m
        u = -(A[i, :]' * θ) * b[i]
        z = @variable(model, [1:2], lower_bound = 0.0)
        @constraint(model, sum(z) <= 1.0)
        @constraint(model, [u - t[i], 1, z[1]] in MOI.ExponentialCone())
        @constraint(model, [-t[i], 1, z[2]] in MOI.ExponentialCone())
    end
    # Add ℓ1 regularization
    @variable(model, 0.0 <= reg)
    @constraint(model, [reg; θ] in MOI.NormOneCone(n + 1))

    @objective(model, Min, sum(t) + λ * reg)

end


nsizes = [10, 100, 500, 1000]

# generate problems according to problem size 
for n in nsizes

    group_name = "exp"
    test_name  = "log_reg_n_" * string(n)
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(logreg_fit, model, $n; kwargs...)
        end
    end
end

nsizes = [2000, 4000, 6000, 8000, 10000]# generate problems according to problem size 
for n in nsizes

    group_name = "large_exp"
    test_name  = "log_reg_n_" * string(n)
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(logreg_fit, model, $n; kwargs...)
        end
    end
end