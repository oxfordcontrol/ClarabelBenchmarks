function cblib_generic(
    model,
    group,
    cblib_problem
)
    cblib_load(model, group, cblib_problem)
    optimize!(model)

    return nothing

end

for group_test_pair in cblib_get_test_names()

    group, file_name = (group_test_pair[1],group_test_pair[2])
    group_name = "cblib_" * group

    #replace "-" with "_" for keys and functions 
    key_name   = replace(file_name,"-" => "_") 
    fcn_name   = Symbol(group_name * "_" *  key_name)

    @eval begin
            @add_problem $group_name $key_name function $fcn_name(
                model,
            )
                return cblib_generic(model, $group, $file_name)
            end
    end
end 

