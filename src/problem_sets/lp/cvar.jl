using Random, StatsBase, Distributions, SparseArrays, LinearAlgebra
using JuMP


@add_problem lp cvar function lp_cvar(
    model,
)

    rng = Random.MersenneTwister(271324)

    m = 13100
    n = 192
    k = 3

    price_scenarios = randn(rng, m, n)
    forward_price_scenarios = randn(rng, m, n)
    asset_energy_limits = randn(rng, n, 2)
    asset_energy_limits[:,2] .= asset_energy_limits[:,1] .+ rand(rng, n)
    bid_curve_prices = randn(rng, n, k)
    cvar_prob = 0.95
    cvar_kappa = 2.0

    num_scenarios, num_assets = size(price_scenarios)
    num_energy_segments = size(bid_curve_prices, 2) + 1
    price_segments = sum(reshape(price_scenarios,m,n,1) .> reshape(bid_curve_prices,1,n,k), dims = 3)
    price_segments = reshape(price_segments,m,n)
    price_segments += repeat(Array(0:n-1)',m,1)*num_energy_segments .+1 # +1 for the indexing difference between julia and python
    price_segments_flat = price_segments[:]
    price_segments_sp = sparse(Array(1:num_scenarios * num_assets),price_segments_flat,ones(num_scenarios * num_assets))

    prices_flat = (price_scenarios - forward_price_scenarios)[:]
    scenario_sum = sparse(repeat(Array(1:num_scenarios), num_assets),Array(1:(num_scenarios * num_assets)),ones(num_scenarios * num_assets))

    A = Array(scenario_sum*Diagonal(prices_flat)*price_segments_sp)
    c = mean(A,dims =1)
    gamma = 1.0 / (1.0 - cvar_prob) / num_scenarios
    kappa = cvar_kappa

    x_min = (repeat(asset_energy_limits[:, 1], 1, num_energy_segments))[:]
    x_max = (repeat(asset_energy_limits[:, 2], 1, num_energy_segments))[:]

    @variable(model, alpha)
    @variable(model, x[1:num_assets*num_energy_segments])
    @variable(model, t[1:size(A,1)])
    @constraint(model, A*x .- alpha .<= t)
    @constraint(model, t .>= 0)
    @constraint(model, x .>= x_min)
    @constraint(model, x .<= x_max)
    @objective(model, Min, dot(c,x))

    optimize!(model)

end