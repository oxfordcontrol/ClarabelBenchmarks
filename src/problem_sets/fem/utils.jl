using JuMP, MathOptInterface

function fem_get_test_names()

    # This will return a vector of (group,filename) pairs

    targets_path = joinpath(@__DIR__,"./../../../../Data/FEM/")
    files       = readdir(targets_path)

    #gets the name of the data files in this group
    files = filter(endswith(".cbf"), files)
    return [splitext(splitext(f)[1])[1] for f in files]
    
end

function fem_load(model, test_name)

    srcpath = joinpath(@__DIR__,"./../../../../Data/FEM/")
    file = joinpath(srcpath,test_name * ".cbf")
    println("file = ", file)
    MathOptInterface.read_from_file(model.moi_backend,file)
end



