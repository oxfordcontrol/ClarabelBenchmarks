using Distributions, JuMP, Random

"""
Taken from https://stanford.edu/~boyd/papers/cvx_short_course.html
Ported from python example implementation provided by Philipp Schiele
"""

function optimal_advertise_build(model)

    rng = Random.MersenneTwister(271324)
    m = 40
    n = 500
    SCALE = 10000
    B = rand(rng, LogNormal(8), m) .+ 10000
    @. B = 1000 * round.(B / 1000)

    P_ad = rand(rng,m,1)
    P_time = rand(rng,1,n)
    P = P_ad*P_time

    T = sin.(LinRange(-2 * pi / 2, 2 * pi - 2 * pi / 2, n)) .* SCALE
    @. T += -minimum(T) + SCALE
    c = rand(rng,m)
    c *= 0.6 * sum(T) / sum(c)
    c .= 1000 .* round.(c ./ 1000)
    R = zeros(m)
    for i = 1:m
        R[i] = rand(rng,LogNormal(minimum(c) / c[i]))
    end

    # Solve optimization problem
    @variable(model, D[1:m,1:n])
    @variable(model, S[1:m])
    @objective(model, Max, sum(S))
    F = diag(P* D')
    @constraint(model, S .<= R .* F )
    @constraint(model, S .<= B)
    @constraint(model,D .>= 0)
    @constraint(model,D' * ones(m) .<= T)
    @constraint(model,D  * ones(n) .>= c)
end

@add_problem lp optimal_advertising function lp_optimal_advertising(
    model; kwargs...
)

    solve_generic(optimal_advertise_build, model; kwargs...)
end
