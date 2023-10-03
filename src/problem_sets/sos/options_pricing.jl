# Section 4.4 of
# A. A. Ahmadi, and A. Majumdar
# DSOS and SDSOS Optimization: More Tractable Alternatives to Sum of Squares and Semidefinite Optimization
# 2017
#
# Taken from Convex.jl problem depot

using MultivariateMoments, DynamicPolynomials, JuMP, SumOfSquares


function options_pricing(model::GenericModel{T}, cone, K) where {T}

    @polyvar x y z
    σ = T[184.04, 164.88, 164.88, 184.04, 164.88, 184.04]
    X = [x^2, x*y, x*z, y^2, y*z, z^2, x, y, z, one(T)]
    μ = measure([σ .+ T(44.21)^2; T(44.21) * ones(T,3); one(T)], X)

    cocone = SumOfSquares.CopositiveInner(cone)

    @variable(model, p, Poly(X))
    @constraint(model, p in cocone)
    @constraint(model, p - (x - K) in cocone)
    @constraint(model, p - (y - K) in cocone)
    @constraint(model, p - (z - K) in cocone)
    @objective(model, Min, dot(μ, p))

end


conemap = Dict("socp" => SDSOSCone(), 
                "sdp" => SDSOSCone(),
                "lp"  => DSOSCone())



#generate problems according to problem type and size 

for K in [5, 10, 20, 30, 35, 40, 45, 50]
    
    for group in keys(conemap)

    group_name = String(group)
    test_name  = "options_pricing_K_" * string(K)
    fcn_name   = Symbol(group_name * "_" * test_name )


    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model; kwargs...
            )
                return solve_generic(options_pricing,model,$conemap[$group],$K; kwargs...)
            end
        end
    end
end 




# Original optimal solutions from original source for reference

# sos_options_pricing_test(optimizer, config)   = options_pricing_test(optimizer, config, SOSCone(), K, sdsos_cosdsos_exp)
# sd_tests["sos_options_pricing"] = sos_options_pricing_test
# sdsos_options_pricing_test(optimizer, config) = options_pricing_test(optimizer, config, SDSOSCone(), K, sdsos_cosdsos_exp)
# soc_tests["sdsos_options_pricing"] = sdsos_options_pricing_test
# dsos_options_pricing_test(optimizer, config)  = options_pricing_test(optimizer, config, DSOSCone(), K, dsos_codsos_exp)
# linear_tests["dsos_options_pricing"] = dsos_options_pricing_test


#const dsos_codsos_exp   = [132.63, 132.63, 132.63, 132.63, 132.63]
#const sdsos_cosdsos_exp = [ 21.51,  17.17,  13.20,   9.85,   7.30]
