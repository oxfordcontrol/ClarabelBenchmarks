using JuMP, MathOptInterface
using ConicBenchmarkUtilities

coneMap = Dict(:Zero => MOI.Zeros, :Free => :Free,
                     :NonPos => MOI.Nonpositives, :NonNeg => MOI.Nonnegatives,
                     :SOC => MOI.SecondOrderCone, :SOCRotated => MOI.RotatedSecondOrderCone,
                     :ExpPrimal => MOI.ExponentialCone, :ExpDual => MOI.DualExponentialCone)


function cblib_get_test_names()

    srcpath = joinpath(@__DIR__,"targets/")
    #get CBLIB archive path and get names of data files
    files = filter(endswith(".cbf.gz"), readdir(srcpath))
    return [splitext(splitext(f)[1])[1] for f in files]

end

function cblib_load(test_name)

    srcpath = joinpath(@__DIR__,"targets/")
    file = joinpath(srcpath,test_name * ".cbf.gz")
    data = readcbfdata(file)
    return data
end


function cblib_fill_model(model,data)

    # In MathProgBase format:
    c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(data)
    # Note: The sense in MathProgBase form is always minimization, and the objective offset is zero.
    # If sense == :Max, you should flip the sign of c before handing off to a solver.
    if sense == :Max
        c .*= -1
    end

    num_con = size(A,1)
    num_var = size(A,2)

    @variable(model, x[1:num_var])

    #Tackling constraint
    for i in eachindex(con_cones)
        cur_cone = con_cones[i]

        if coneMap[cur_cone[1]] == :Free
            continue
        elseif coneMap[cur_cone[1]] == MOI.ExponentialCone
            @constraint(model, b[cur_cone[2]] - A[cur_cone[2],:]*x in MOI.ExponentialCone())
        # elseif coneMap[cur_cone[1]] == MOI.DualExponentialCone
        #     @constraint(model, b[cur_cone[2]] - A[cur_cone[2],:]*x in MOI.DualExponentialCone())
        else
            @constraint(model, b[cur_cone[2]] - A[cur_cone[2],:]*x in coneMap[cur_cone[1]](length(cur_cone[2])))
        end
    end

    for i in eachindex(var_cones)
        cur_var = var_cones[i]

        if coneMap[cur_var[1]] == :Free
            continue
        elseif coneMap[cur_var[1]] == MOI.ExponentialCone
            @constraint(model, x[cur_var[2]] in MOI.ExponentialCone())
        # elseif coneMap[cur_var[1]] == MOI.DualExponentialCone
        #     @constraint(model, x[cur_var[2]] in MOI.DualExponentialCone())
        else
            @constraint(model, x[cur_var[2]] in coneMap[cur_var[1]](length(cur_var[2])))
        end
    end

    @objective(model, Min, sum(c.*x))

end


