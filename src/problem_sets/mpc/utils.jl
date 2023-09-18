using JuMP, MathOptInterface, MAT

function mpc_get_test_names()

    srcpath = joinpath(@__DIR__,"targets/")

    # force path creation, e.g. if matlab make wasn't run
    ispath(srcpath) || mkdir(srcpath)

    #get Maros archive path and get names of data files
    files = filter(endswith(".mat"), readdir(srcpath))
    return [splitext(f)[1] for f in files]
    
end



function mpc_load(test_name)

    srcpath = joinpath(@__DIR__,"targets/")
    file = joinpath(srcpath,test_name * ".mat")
    mat = matread(file)
    return clean_imported_data(mat["data"])
end


function clean_imported_data(data)

    #get rid of matlab "empty" terms
    empty = Matrix{Float64}(undef, 0, 0)
    for key in keys(data)
        if data[key] == empty
            data[key] = nothing
        end
    end

    #get system dimensions 
    (nx,nu) = size(data["B"])

    if isnothing(data["C"])
        ny = 0
    else 
        (ny,~)  = size(data["C"])
    end

    #if f is empty, set it to zero
    if isnothing(data["f"])
        data["f"] = zeros(nx)
    end

    if isnothing(data["e"])
        data["e"] = zeros(ny)
    end

    #force Q and R to be matrices if they are scalar 
    if isa(data["Q"],Float64); data["Q"] = [data["Q"];;]; end 
    if isa(data["R"],Float64); data["R"] = [data["R"];;]; end 

    #set horizon to integer value 
    data["ni"] = Int(data["ni"])

    #concatenate matlab cell arrays into matrices or leave as a scalar
    if !isnothing(data["yr"]) && !isa(data["yr"],Float64)
        data["yr"] = hcat(data["yr"]...)
    end
    if !isnothing(data["ur"]) && !isa(data["ur"],Float64)
        data["ur"] = hcat(data["ur"]...)
    end

    return data 

end