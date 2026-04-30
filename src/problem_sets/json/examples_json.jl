function json_generic(model, test_name)
    json_load(model, test_name)
    return nothing
end

for test_name in json_get_test_names()
    group_name = "json"

    # Replace "-" with "_" for keys and function names.
    key_name = replace(test_name, "-" => "_")
    fcn_name = Symbol(group_name * "_" * key_name)

    @eval begin
        @add_problem $group_name $key_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(json_generic, model, $test_name; kwargs...)
        end
    end
end
