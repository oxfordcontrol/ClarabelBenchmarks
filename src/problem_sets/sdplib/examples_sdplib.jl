function sdplib_generic(
    model,
    filename
)

    filename = joinpath(@__DIR__,"targets/",filename * ".dat-s")

    src = MOI.FileFormats.Model(;format = MOI.FileFormats.FORMAT_SDPA, filename = filename)
    MOI.read_from_file(src,filename)

    MOI.copy_to(model,src)

    return nothing

end

function sdplib_get_test_names()

  srcpath = joinpath(@__DIR__,"targets/")
  #get Maros archive path and get names of data files
  files = filter(endswith(".dat-s"), readdir(srcpath))
  return [splitext(f)[1] for f in files]

end



for filename in sdplib_get_test_names()

    group_name = "sdplib"

    test_name = filename;

    #replace "-" with "_" for keys and functions 
    key_name   = replace(filename,"-" => "_") 
    fcn_name   = Symbol(group_name * "_" *  key_name)

    @eval begin
            @add_problem $group_name $key_name function $fcn_name(
                model; kwargs...
            )
                return solve_generic(sdplib_generic, model, $test_name; kwargs...)
            end
    end
end 





