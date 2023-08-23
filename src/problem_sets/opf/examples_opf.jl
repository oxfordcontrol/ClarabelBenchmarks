using JuMP, PowerModels

function power_models_generic(
    model,
    opf_problem_type,
    filepath,
)
    power_model = PowerModels.instantiate_model(
        PowerModels.parse_file(filepath),
        opf_problem_type,
        PowerModels.build_opf;
        jump_model = model,
    )
    optimize!(model)

    return nothing

end


groups = Dict("sdp"  => PowerModels.SparseSDPWRMPowerModel,
              "socp" => PowerModels.SOCWRConicPowerModel,
              "lp"   => PowerModels.DCPPowerModel)

tests  = powermodels_get_test_names()

for (group,opf_model_type) in pairs(groups) 

    group_name = "opf_" * group

    for (test_name,filepath) in pairs(tests)

    #limit the size of the SDP problems
    #since the build times are very long
    if(group == "sdp")
        is_number_of_nodes_ok(test_name) || continue
    end

    fcn_name = Symbol(group_name * "_" * test_name)

        @eval begin
                @add_problem $group_name $test_name function $fcn_name(
                    model,
                )
                    return power_models_generic(model, $opf_model_type, $filepath)
                end
        end
    end 
end 

