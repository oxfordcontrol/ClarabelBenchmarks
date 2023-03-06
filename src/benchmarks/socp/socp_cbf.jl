using ConicBenchmarkUtilities
using Clarabel
using MathOptInterface, JuMP
const MOI = MathOptInterface

coneMap = Dict(:Zero => MOI.Zeros, :Free => :Free,
                     :NonPos => MOI.Nonpositives, :NonNeg => MOI.Nonnegatives,
                     :SOC => MOI.SecondOrderCone, :SOCRotated => MOI.RotatedSecondOrderCone,
                     :ExpPrimal => MOI.ExponentialCone, :ExpDual => MOI.DualExponentialCone)

filelist = readdir(pwd()*"./socp_cblib")
Socplist = String[]

i = 4 
# for i in eachindex(filelist)
    datadir = filelist[i]
    println("Current file ", i, " is ", datadir)
    dat = readcbfdata("./socp_cblib/"*datadir) # .cbf.gz extension also accepted

    model = Model(Clarabel.Optimizer)

    c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(dat)

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

    results = optimize!(model)
# end
