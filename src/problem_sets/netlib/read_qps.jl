using QPSReader, SparseArrays, LinearAlgebra
using JuMP, MathOptInterface
using MAT
using ECOS, Clarabel
using Mosek, MosekTools
const MOI = MathOptInterface
# Read data 
#   min     c'x
# s.t.  lcon ≤ Ax ≤ ucon
#       lvar ≤ x ≤ uvar

# filelist = readdir(pwd()*"./MPS\\MPS")
# for ind in eachindex(filelist)
#     datadir = filelist[ind]
#     println(ind, "  ", datadir)

#     readqps("./MPS/MPS/"*datadir)   
# end

# qps = readqps("MPS\\MPS\\blend")

# m = qps.ncon
# n = qps.nvar
# lvar = qps.lvar
# uvar = qps.uvar
# lcon = qps.lcon
# ucon = qps.ucon
# P = sparse(qps.qrows,qps.qcols,qps.qvals)
# A = sparse(qps.arows,qps.acols,qps.avals)
# c0 = qps.c0
# c = qps.c
# model = Model(Clarabel.Optimizer)

# @variable(model, x[1:n])
# @objective(model, Min, c'*x)
# @constraint(model, lcon .<= A*x .<= ucon)
# @constraint(model, lvar .<= x .<= uvar)

# optimize!(model)

filelist = readdir(pwd()*"./feasibleLP/")
success_num = 0
almost_success_num = 0
total_iter = zeros(length(filelist))

# for ind in eachindex(filelist)
ind = 95
    datadir = filelist[ind]
    println(ind, "  ", datadir)
    
    mps = matread("feasibleLP/"*datadir)
    # mps = mps["Problem"]
    A = mps["A"]
    m,n = size(A)
    b = mps["b"][:]
    lo = mps["lo"][:]
    hi = mps["hi"][:]
    c = mps["c"][:]
    
    l = similar(lo)
    u = similar(hi)
    
    # Set a bound to infinity if it is too large
    for i in eachindex(lo)
        l[i] = lo[i]<-sqrt(1/eps(Float64)) ? -Inf : lo[i]
    end
    for i in eachindex(hi)
        u[i] = hi[i] > sqrt(1/eps(Float64)) ? Inf : hi[i]
    end
    
    model = Model(Clarabel.Optimizer)
    # set_optimizer_attribute(model, "tol_ktratio", 1e-6)
    @variable(model, x[1:n])
    @objective(model, Min, c'*x)
    @constraint(model, A*x .== b)
    @constraint(model, l .<= x .<= u)
    
    optimize!(model)
    
    state = termination_status(model)
    if state == MOI.OPTIMAL
    global    success_num += 1
    elseif state == MOI.ALMOST_OPTIMAL
    global    almost_success_num += 1
    end
# end

