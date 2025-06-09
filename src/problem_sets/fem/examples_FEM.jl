function fem_generic(
    model,
    fem_problem
)
    fem_load(model, fem_problem)
    return nothing

end

for file_name in fem_get_test_names()
    group_name = "sdp_fem"


    fcn_name   = Symbol(group_name * "_" * file_name)

    @eval begin
            @add_problem $group_name $file_name function $fcn_name(
                model; kwargs...
            )
                return solve_generic(fem_generic, model, $file_name; kwargs...)
            end
    end
end 
