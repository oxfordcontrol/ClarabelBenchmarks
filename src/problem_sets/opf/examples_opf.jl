using JuMP, PowerModels

function power_models_generic(
    model,
    opf_problem_type,
    filepath,
)

    PowerModels.silence()

    power_model = PowerModels.instantiate_model(
        PowerModels.parse_file(filepath),
        opf_problem_type,
        PowerModels.build_opf;
        jump_model = model,
    )

    return nothing

end


groups = Dict("sdp"  => PowerModels.SparseSDPWRMPowerModel,
              "socp" => PowerModels.SOCWRConicPowerModel,
              "lp"   => PowerModels.DCPPowerModel)

tests  = powermodels_get_test_names()

for (group,opf_model_type) in pairs(groups) 

    group_name = "opf_" * group

    for (test_name,filepath) in pairs(tests)

    #filter out problems with too many nodes
    #since some of these problems are very slow
    is_number_of_nodes_ok(test_name,group) || continue

    fcn_name = Symbol(group_name * "_" * test_name)

        @eval begin
                @add_problem $group_name $test_name function $fcn_name(
                    model; kwargs...
                )
                    return solve_generic(power_models_generic,model, $opf_model_type, $filepath; kwargs...)
                end
        end
    end 
end 

