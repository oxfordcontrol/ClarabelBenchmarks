using JuMP, MathOptInterface, MAT

function sslsq_get_test_names()

    srcpath = joinpath(@__DIR__,"targets/")
    #get Maros archive path and get names of data files
    files = filter(endswith(".mat"), readdir(srcpath))
    return [splitext(f)[1] for f in files]
    
end



function sslsq_load(test_name)

    srcpath = joinpath(@__DIR__,"targets/")
    file = joinpath(srcpath,test_name * ".mat")
    probdata = matread(file)
    return (probdata["A"],probdata["b"])
end
