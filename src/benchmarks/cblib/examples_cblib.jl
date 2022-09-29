function cblib_generic(
    model,
    cblib_problem
)
    data = cblib_load(cblib_problem)
    cblib_fill_model(model,data)
    optimize!(model)

    return nothing

end

for test_name in cblib_get_test_names()
    fcn_name = Symbol("cblib_" * test_name)
    @eval begin
            @add_problem cblib function $fcn_name(
                model,
            )
                return cblib_generic(model,$test_name)
            end
    end
end 

