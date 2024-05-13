using LinearAlgebra, SparseArrays, Random
using Clarabel
using JuMP

"""
Entropy maximization problem from A.2 in POGS paper.
https://web.stanford.edu/~boyd/papers/pdf/pogs.pdf

Conic reformulation:
t <- x log x

So, an equivalent optimization problem is:
    maximize -∑ t_i
    s.t.     t_i <= x_i log x_i, i = 1, ..., n
            sum(x) = 1
            Ax ≤ b

Then, the first constraint can be rewritten as a conic constraint:
    (t_i, x_i, 1) in Exponential Cone, i = 1, ..., n
"""

function entropy_max_fit(model::GenericModel{T}, m, n) where {T}

    rng = Random.MersenneTwister(40701)

    A = sprandn(rng, T, m, n, 0.125) * T(sqrt(n)) # draws from N(0, n)
    v = rand(rng, T, n)

    b = A * v / sum(v)

    @variable(model, x[1:n])
    @variable(model, t[1:n])
    for i in 1:n
        @constraint(model, [x[i], t[i], 1] in MOI.ExponentialCone())
    end
    # Simplex constraints
    @constraint(model, x .>= 0)
    @constraint(model, x .<= 1)
    @constraint(model, sum(x) == 1)
    @constraint(model, A*x .<= b)
    
    @objective(model, Max, -sum(t))
end

nsizes = [10, 100, 1000]
for n in nsizes

    # Pick m < n (can change this later) TODO
    m = round(Int, 0.5 * n)

    test_name = "entropy_max_N_" * string(n)
    group_name = "entropy_maximization"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(entropy_max_fit, model, $m, $n; kwargs...)
        end
    end
end
