#using Revise
using LinearAlgebra
using Printf
using MAT
using JuMP
using Hypatia
using JLD2

Base.@kwdef mutable struct TestResult
    time::Float64
    status::MOI.TerminationStatusCode
    cost::Float64
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


function solve_hypatia(vars; verbose = false, maxiter)

    P,c,Aineq,bineq,Aeq,beq = data_ecos_form_eq(vars)

    model = Model(Hypatia.Optimizer)
    @variable(model, x[1:length(c)])
    @constraint(model, c1, Aineq*x .<= bineq)
    @constraint(model, c2, Aeq*x .== beq)
    @objective(model, Min, sum(c.*x) + 1/2*x'*P*x)

    #Run the opimization
    #set_optimizer_attribute(model, "iter_limit", maxiter)
    set_optimizer_attribute(model, "verbose", Int64(verbose))

    try
        optimize!(model)
        time = JuMP.solve_time(model)
        cost = JuMP.objective_value(model)
        status = JuMP.termination_status(model)
        return TestResult(time,status,cost)
    catch
        println("Hypatia FAIL")
        time = NaN
        cost = NaN
        status = MOI.OTHER_ERROR
        return TestResult(time,status,cost)
    end

end


srcpath = joinpath(@__DIR__,"mat")
#get Maros archive path and get names of data files
files = filter(endswith(".mat"), readdir(srcpath))

result_hypatia = []
names = []

solve_list = 1:length(files)
#solve_list = 90
verbosity = false

for FNUM = solve_list #length(files)

    #if(any(FNUM .== badfiles))
    #    continue
    #end

    push!(names,files[FNUM][1:end-4])

    println("SOLVING PROBLEM ", names[end], " FILE NUMBER, ", FNUM)

    #load problem data
    println("Loading file")
    thisfile = joinpath(srcpath,files[FNUM])
    probdata = matread(thisfile)

    this = solve_hypatia(probdata, verbose = verbosity, maxiter = 100)
    push!(result_hypatia,this)
    println("Result Hypatia: ", result_hypatia[end].status)

end


jldsave("maros_run_hypatia.jld2"; names,result_hypatia)
