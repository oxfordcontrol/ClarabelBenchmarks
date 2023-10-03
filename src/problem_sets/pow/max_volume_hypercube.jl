using LinearAlgebra, SparseArrays, Random
using MosekTools
using Clarabel
using Hypatia
"""
Maximum volume hypercube} from Hypatia.jl,

https://github.com/chriscoey/Hypatia.jl/tree/master/examples/maxvolume,
"""


function max_vol_hypercube_data(n)

    rng = Random.MersenneTwister(271324 + n)

    x = randn(rng,n)
    A = sparse(1.0*I(n))
    gamma = norm(A * x) / sqrt(n)
    freq = ones(n)
    freq ./= n

    (A,gamma,freq)

end 

function max_vol_hypercube_pow(model, n)

    (A,gamma,freq) = max_vol_hypercube_data(n)

    @variable(model, x[1:n])
    @variable(model,z[1:n-1])
    @objective(model, Max, z[end])

    # transform a general power cone into a product of three-dimensional power cones
    power = freq[1] + freq[2]
    @constraint(model, vcat(x[2],x[1],z[1]) in MOI.PowerCone(freq[2]/power))
    @constraint(model, vcat(gamma, A * x) in MOI.NormInfinityCone(n + 1))
    @constraint(model, vcat(sqrt(n) * gamma, A * x) in MOI.NormOneCone(n + 1))

    #MOSEK does not support this model directly and requires extra variables
    if solver_name(model) == "Mosek"
        @variable(model,r[1:n-2])
        for i = 1:n-2
            power += freq[i+2]
            @constraint(model, r[i] == z[i])
            @constraint(model, vcat(x[i+2],r[i],z[i+1]) in MOI.PowerCone(freq[i+2]/power))
        end
    else 
        for i = 1:n-2
            power += freq[i+2]
            @constraint(model, vcat(x[i+2],z[i],z[i+1]) in MOI.PowerCone(freq[i+2]/power))
        end
    end

end 

function max_vol_hypercube_genpow(model, n)

    (A,gamma,freq) = max_vol_hypercube_data(n)

    @variable(model, t)
    @variable(model, x[1:n])
    @objective(model, Max, t)
    @constraint(model, vcat(gamma, A * x) in MOI.NormInfinityCone(n + 1))
    @constraint(model, vcat(sqrt(n) * gamma, A * x) in MOI.NormOneCone(n + 1))

    # Clarabel and Hypatia support this directly 
    if solver_name(model) ∈ ["Clarabel","ClarabelRs"]
        @constraint(model, vcat(x,t) in Clarabel.MOI.GenPowerCone(freq,1))
    elseif solver_name(model) == "Hypatia"
        @constraint(model, vcat(x,t) in Hypatia.GeneralizedPowerCone(freq,1,false))
    else 
        error("Generalized power cone not supported by solver: ", solver_name(model))
    end 

end 

#generate problems according to problem size

nsizes = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000,10000,20000,50000,100000]

for n in nsizes

    test_name  = "MVH_" * string(n)
    group_name = "pow"
    fcn_name   = Symbol(group_name * "_" * test_name )

    #3D power cone 
    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(max_vol_hypercube_powmodel,$n; kwargs...)
        end
    end

    group_name = "genpow"
    fcn_name   = Symbol(group_name * "_" * test_name )

    #generalized power cone
    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(max_vol_hypercube_genpow,model,$n; kwargs...)
        end
    end

end
