using Revise
using Clarabel
using Printf
using MAT, JuMP
using LinearAlgebra
using Clarabel
using Printf
using DelimitedFiles, Statistics


file = "HS76.mat"

srcpath = joinpath(@__DIR__,"mat",file)

probdata = matread(srcpath)

#solve_ecos(probdata)
#solve_osqp(probdata)
verbosity = true

#solve_scs(probdata)
out=  solve_clarabel(probdata; verbose = verbosity, maxiter = 500, solver=:mkl)

#solve_gurobi(probdata;presolve=true,verbose = verbosity)
P,c,A,b,cone_types,cone_dims = data_clarabel_form_eq(probdata)

solver = out[2]

return nothing
