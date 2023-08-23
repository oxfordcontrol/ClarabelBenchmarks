using Random, StatsBase, Distributions
using JuMP

"""
Taken from https://stanford.edu/~boyd/papers/cvx_short_course.html
Ported from python example implementation provided by Philipp Schiele
"""


function lp_svm_L1(
    model,
    n = 10,
    m = 50*n,
    density = 0.2,
)
    rng = Random.MersenneTwister(271324 + m + n)

    beta_true = randn(rng, n, 1)
    idxs = sample(rng, 1:n, Int((1 - density) * n); replace = false)
    for ind in idxs
        beta_true[ind] = 0
    end
    offset = 0
    sigma = 45
    X = rand(rng,Normal(0, 5), m, n)
    Y = sign.(X*beta_true .+ offset .+ rand(rng,Normal(0, sigma), m, 1))
    λ = 0.1

    @variable(model, β[1:n])
    @variable(model, v)
    @variable(model, α)
    @variable(model, t[1:m])
    @constraint(model, 1.0 .- Y.*(X*β .- v) .<= t)
    @constraint(model, t .>= 0)
    @constraint(model, [α; β] in MOI.NormOneCone(length(β) + 1))
    @objective(model, Min, sum(t)/m + λ*α)
    optimize!(model)

end

#generate problems according to problem size

for n in [10, 20, 50, 100]

    group_name = "lp"
    test_name  = "svm_L1_n_" * string(n)
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model,
        )
            return lp_svm_L1(model,$n)
        end
    end
end

