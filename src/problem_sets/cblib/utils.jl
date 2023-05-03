using JuMP, MathOptInterface
using ConicBenchmarkUtilities

coneMap = Dict(:Zero => MOI.Zeros, :Free => :Free,
                     :NonPos => MOI.Nonpositives, :NonNeg => MOI.Nonnegatives,
                     :SOC => MOI.SecondOrderCone, :SOCRotated => MOI.RotatedSecondOrderCone,
                     :ExpPrimal => MOI.ExponentialCone, :ExpDual => MOI.DualExponentialCone)


function cblib_get_test_names()

    # This will return a vector of (group,filename) pairs

    targets_path = joinpath(@__DIR__,"targets/")
    groups       = readdir(targets_path)
    pairs = [];

    for group = groups
        srcpath = joinpath(targets_path,group)

        #gets the name of the data files in this group
        files = filter(endswith(".cbf.gz"), readdir(srcpath))
        append!(pairs, [ (group => splitext(splitext(f)[1])[1]) for f in files])
    end
    return pairs
end


function cblib_load(model, group, test_name)

    srcpath = joinpath(@__DIR__,"targets/",group)
    file = joinpath(srcpath,test_name * ".cbf.gz")
    println("file = ", file)
    MathOptInterface.read_from_file(model,file)
end



