using LinearAlgebra, SparseArrays
using MosekTools
using Clarabel
using Hypatia
"""
Maximum volume hypercube} from Hypatia.jl,

https://github.com/chriscoey/Hypatia.jl/tree/master/examples/maxvolume,
"""

function max_likelihood_data(d)

    rng = Random.MersenneTwister(271324 + d)

    freq = Float64.(rand(rng, 1:(2 * d), d))
    freq ./= sum(freq)      # normalize the sum to be 1

    return freq 

end 

function max_likelihood_pow(model, d)

    freq = max_likelihood_data(d)

    @variable(model, p[1:d])
    @variable(model,q[1:d-1])
    @objective(model, Min, -q[end])
    @constraint(model, sum(p) == 1)
    # transform general power cone into a product of three-dimensional power cones
    power = freq[1] + freq[2]
    @constraint(model, vcat(p[2],p[1],q[1]) in MOI.PowerCone(freq[2]/power))

    #MOSEK does not support this model directly and requires extra variables
    if solver_name(model) == "Mosek"
        @variable(model,r[1:d-2])
        for i = 1:d-2
            power += freq[i+2]
            @constraint(model, r[i] == q[i])
            @constraint(model, vcat(p[i+2],r[i],q[i+1]) in MOI.PowerCone(freq[i+2]/power))
        end
    else
        for i = 1:d-2
            power += freq[i+2]
            @constraint(model, vcat(p[i+2],q[i],q[i+1]) in MOI.PowerCone(freq[i+2]/power))
        end
    end

end 

function max_likelihood_genpow(model, d)

    freq = max_likelihood_data(d)

    @variable(model, p[1:d])
    @variable(model, t)
    @objective(model, Min, -t)
    @constraint(model, sum(p) == 1)

    # Clarabel and Hypatia support this directly 
    if solver_name(model) ∈ ["Clarabel","ClarabelRs"]
        @constraint(model, vcat(p,t) in Clarabel.MOI.GenPowerCone(freq,1))
    elseif solver_name(model) == "Hypatia"
        @constraint(model, vcat(p,t) in Hypatia.GeneralizedPowerCone(freq,1,false))
    else 
        error("Generalized power cone not supported by solver: ", solver_name(model))
    end 

end 

#generate problems according to problem size

dsizes = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000,10000,20000,50000,100000]

for d in dsizes

    test_name  = "DML_" * string(d)
    group_name = "pow"
    fcn_name   = Symbol(group_name * "_" * test_name )

    #3D power cone 
    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(max_likelihood_pow,model,$d; kwargs...)
        end
    end

    group_name = "genpow"
    fcn_name   = Symbol(group_name * "_" * test_name )

    #generalized power cone
    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(max_likelihood_genpow,model,$d; kwargs...)
        end
    end

end
