
using MAT, JuMP
using LinearAlgebra
using Clarabel
using Printf
using DelimitedFiles, Statistics

Base.@kwdef mutable struct TestResult
    time::Float64
    status::MOI.TerminationStatusCode
    cost::Float64
end

function mean(r::Vector{TestResult})
    out = deepcopy(r[1])
    t   = Statistics.mean([test.time for test in r])
    out.time = t
    return out
end

function median(r::Vector{TestResult})
    out = deepcopy(r[1])
    t   = Statistics.median([test.time for test in r])
    out.time = t
    return out
end

function Base.min(r::Vector{TestResult})
    out = deepcopy(r[1])
    t   = Statistics.min([test.time for test in r])
    out.time = t
    return out
end


function dropinfs(A,b)

    b = b[:]
    finidx = findall(<(5e19), abs.(b))
    b = b[finidx]
    A = A[finidx,:]
    return A,b

end

function data_osqp_form(vars)

    n = Int(vars["n"])
    m = Int(vars["m"])
    A   = vars["A"]
    P   = vars["P"]
    c   = vars["q"][:]
    c0  = vars["r"]
    l   = vars["l"][:]
    u   = vars["u"][:]

    #force a true double transpose
    #to ensure data is sorted within columns
    A = (A'.*1)'.*1
    P = (P'.*1)'.*1

    return P,c,A,l,u
end

function data_ecos_form(vars)

    P,c,A,l,u = data_osqp_form(vars)
    #make into single constraint
    A = [A; -A]
    b = [u;-l]
    A,b = dropinfs(A,b)

    return P,c,A,b

end

function data_ecos_form_eq(vars)

    P,c,A,l,u = data_osqp_form(vars)

    #separate into equalities and inequalities
    eqidx = l .== u
    Aeq = A[eqidx,:]
    beq = l[eqidx]

    #make into single constraint
    Aineq = A[.!eqidx,:]
    lineq = l[.!eqidx,:]
    uineq = u[.!eqidx,:]
    Aineq = [Aineq; -Aineq]
    bineq = [uineq;-lineq]
    Aineq,bineq = dropinfs(Aineq,bineq)

    return P,c,Aineq,bineq,Aeq,beq

end

function data_clarabel_form_eq(vars)

    P,c,Aineq,bineq,Aeq,beq = data_ecos_form_eq(vars)

    cones = Vector{Clarabel.SupportedCone}()
    if(length(beq) > 0)
        push!(cones,Clarabel.ZeroConeT(length(beq)))
    end
    if(length(bineq) > 0)
        push!(cones,Clarabel.NonnegativeConeT(length(bineq)))
    end

    A = [Aeq;Aineq]
    b = [beq;bineq]

    return P,c,A,b,cones
end



function data_clarabel_form(vars)

    P,c,A,b = data_ecos_form(vars)
    m = length(b)
    n = length(c)

    cones = [Clarabel.NonnegativeConeT(length(b))]

    return P,c,A,b,cone_types,cones
end


function solve_ecos(vars; verbose = false, maxiter = 100)

    P,c,Aineq,bineq,Aeq,beq = data_ecos_form_eq(vars)


    #see if cholesky fails.  If so, try to fix it
    try
        cholesky(P)
    catch
        P = P+1e-10*I
    end


    model = Model(ECOS.Optimizer)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)

    #Run the opimization
    set_optimizer_attribute(model, "verbose", verbose)
    set_optimizer_attribute(model, "maxit", maxiter)
    try
        optimize!(model)
        time = JuMP.solve_time(model)
        cost = JuMP.objective_value(model)
        status = JuMP.termination_status(model)
        return TestResult(time,status,cost)
    catch
        println("ECOS FAIL")
        time = NaN
        cost = NaN
        status = MOI.OTHER_ERROR
        return TestResult(time,status,cost)
    end

end

function solve_scs(vars; verbose = false, maxiter = 100)

    P,c,Aineq,bineq,Aeq,beq = data_ecos_form_eq(vars)

    #see if cholesky fails.  If so, try to fix it
    try
        cholesky(P)
    catch
        P = P+1e-10*I
    end


    model = Model(SCS.Optimizer)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)

    #Run the opimization
    set_optimizer_attribute(model, "verbose", verbose)
    try
        optimize!(model)
        time = JuMP.solve_time(model)
        cost = JuMP.objective_value(model)
        status = JuMP.termination_status(model)
        return TestResult(time,status,cost)
    catch
        println("SCS FAIL")
        time = NaN
        cost = NaN
        status = MOI.OTHER_ERROR
        return TestResult(time,status,cost)
    end

end


function solve_gurobi(vars; presolve = true, threads = -1, verbose = false)

    P,c,Aineq,bineq,Aeq,beq = data_ecos_form_eq(vars)

    model = Model(Gurobi.Optimizer)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)

    #Run the opimization
    set_optimizer_attribute(model, "OutputFlag", verbose)
    set_optimizer_attribute(model, "Presolve", presolve)
    if(threads >= 1)
        set_optimizer_attribute(model, "Threads", threads)
    end

    try
        optimize!(model)
        time = JuMP.solve_time(model)
        cost = JuMP.objective_value(model)
        status = JuMP.termination_status(model)
        return TestResult(time,status,cost)
    catch
        println("GUROBI FAIL")
        time = NaN
        cost = NaN
        status = MOI.OTHER_ERROR
        return TestResult(time,status,cost)
    end

end

function solve_mosek(vars; verbose = false)

    P,c,Aineq,bineq,Aeq,beq = data_ecos_form_eq(vars)

    model = Model(Mosek.Optimizer)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)
    set_optimizer_attribute(model, "LOG", verbose)


    try
        optimize!(model)
        time = JuMP.solve_time(model)
        cost = JuMP.objective_value(model)
        status = JuMP.termination_status(model)
        return TestResult(time,status,cost)
    catch
        println("MOSEK FAIL")
        time = NaN
        cost = NaN
        status = MOI.OTHER_ERROR
        return TestResult(time,status,cost)
    end

end





function solve_osqp(vars; verbose = false)

    #use ECOS style constraints.   Probably works
    #out to be the same since everything is just
    #converted to one sided and then back
    P,c,A,b = data_ecos_form(vars)

    model = Model(OSQP.Optimizer)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, A*x .<= b)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)

    #Run the opimization
    set_optimizer_attribute(model, "verbose", verbose)
    optimize!(model)


    time = JuMP.solve_time(model)
    cost = JuMP.objective_value(model)
    status = JuMP.termination_status(model)

    return TestResult(time,status,cost)

end

function solve_clarabel(vars; solver = :mkl, verbose = false, maxiter = 100)

    P,c,A,b,cones = data_clarabel_form_eq(vars)
    settings = Clarabel.Settings(
            max_iter=maxiter,
            direct_kkt_solver=true,
            #static_regularization_eps = 1e-7,
            dynamic_regularization_delta = 2e-7,
            dynamic_regularization_eps = 1e-13,
            verbose = verbose,
            equilibrate_enable = true,
            direct_solve_method = solver
    )
    solver   = Clarabel.Solver(P,c,A,b,cones,settings)
    Clarabel.solve!(solver)

    time = solver.info.solve_time
    cost = solver.info.cost_primal

    if(any(isnan.(solver.variables.x)))
        status = MOI.OTHER_ERROR
    elseif(solver.info.status == Clarabel.SOLVED)
        status = MOI.OPTIMAL
    elseif(solver.info.status == Clarabel.PRIMAL_INFEASIBLE)
        status = MOI.INFEASIBLE
    elseif(solver.info.status == Clarabel.DUAL_INFEASIBLE)
        status = MOI.DUAL_INFEASIBLE
    elseif(solver.info.status == Clarabel.MAX_ITERATIONS)
        status = MOI.ITERATION_LIMIT
    elseif(solver.info.status == Clarabel.TIME)
        status = MOI.TIME_LIMIT
    else
        status = MOI.OTHER_ERROR
    end

    return TestResult(time,status,cost), solver

end

struct MarosSolutionData
    M
    N
    NZ
    QN
    QNZ
    OPT
end

function get_ref_solutions(filename)

    data = readdlm(filename;header=true)[1]
    #drops second header element.  Last column is objective
    out = Dict{String,MarosSolutionData}()

    for i = 1:size(data,1)
        key = uppercase(data[i,1])
        M = data[i,2]
        N = data[i,3]
        NZ = data[i,4]
        QN = data[i,5]
        QNZ = data[i,6]
        OPT = data[i,7]
        obj = MarosSolutionData(M,N,NZ,QN,QNZ,OPT)
        out[key] = obj
    end

    return out

end
