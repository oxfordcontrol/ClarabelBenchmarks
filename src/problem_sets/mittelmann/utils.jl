function mittelmann_get_test_names()

    srcpath = joinpath(@__DIR__,"./data/")
    #get Maros archive path and get names of data files
    files = filter(endswith(".mps.bz2"), readdir(srcpath))
    return [String(split(f,".")[1]) for f in files]

end

function mittelmann_generic(model::GenericModel,test_name::String)

    srcpath = joinpath(@__DIR__,"./data/")
    file = joinpath(srcpath,test_name * ".mps.bz2")

    src = MOI.FileFormats.Model(; format = MOI.FileFormats.FORMAT_MPS, filename = file)
    MOI.read_from_file(src,file)
    MOI.copy_to(model,src)

    return nothing
end

for test_name in mittelmann_get_test_names()
    
    group_name = "mittelmann_lp"
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
            @add_problem $group_name $test_name function $fcn_name(
                model; kwargs...
            )
                return solve_generic(mittelmann_generic,model,$test_name; kwargs...)
            end
    end
end 