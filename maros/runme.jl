#using Revise
using Clarabel
include(joinpath(@__DIR__,"utils.jl"))
using LinearAlgebra
using Printf
using MAT
using JuMP
using OSQP, ECOS, Gurobi,MosekTools
using JLD2
using StatProfilerHTML



function print_header()

    println("                             ECOS                             CLARABEL          ")
    println("                  TIME       STAT       COST      |   TIME       STAT       COST      |   REFOBJ     SPEEDUP ")
    println("------------------------------------------------------------------------------------------------")

end

function print_row(i,name,result_ecos,result_clarabel, ref_sol)

    @printf("%3d %-9s : ", i, name)

    for result in [result_ecos,result_clarabel]
        stat = @sprintf("%s",result.status)[1:6]
        @printf("%+9.2e   %-4s    %+10.3e  : ", result.time, stat, result.cost)
    end
    speedup = result_ecos.time / result_clarabel.time
    @printf("%+9.3e  ", ref_sol)
    @printf("%+9.3f  ", speedup)
    @printf("\n")

end



srcpath = joinpath(@__DIR__,"mat")
#get Maros archive path and get names of data files
files = filter(endswith(".mat"), readdir(srcpath))


result_ecos = []
result_scs = []
result_osqp = []
result_clarabel = []
result_clarabel_cholmod = []
result_gurobi = []
result_gurobi_no_presolve = []
result_gurobi_single_thread = []
result_mosek = []
names = []

#These file indices cause segfaults in JuMP (not ECOS).  Just skip them
#badfiles = [78, 79, 117]
#push!(badfiles,36)   #this is EXDATA, which is huge

solve_list = 1:length(files)
#solve_list = 83   #very small
verbosity = false
K = 3

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

    push!(result_ecos, median([solve_ecos(probdata; verbose = verbosity, maxiter = 100) for i = 1:K]))
    println("Result ECOS: ", result_ecos[end].status, " time = ",result_ecos[end].time )

    push!(result_osqp, median([solve_osqp(probdata, verbose = verbosity) for i = 1:K]))
    println("Result OSQP: ", result_osqp[end].status, " time = ",result_osqp[end].time )

    # push!(result_clarabel,solve_scs(probdata; verbose = verbosity, maxiter = 100)[1])
    # println("Result SCS: ", result_scs[end].status, " time = ",result_clarabel[end].time )

    push!(result_clarabel,median([solve_clarabel(probdata; verbose = verbosity, maxiter = 100, solver=:qdldl)[1] for i = 1:K]))
    println("Result Clarabel (QDLDL): ", result_clarabel[end].status, " time = ",result_clarabel[end].time )

    push!(result_clarabel_cholmod,median([solve_clarabel(probdata; verbose = verbosity, maxiter = 100, solver=:cholmod)[1] for i = 1:K]))
    println("Result Clarabel (cholmod): ", result_clarabel_cholmod[end].status, " time = ",result_clarabel_cholmod[end].time )

    push!(result_gurobi,median([solve_gurobi(probdata; presolve=true, verbose = verbosity) for i = 1:K]))
    println("Result Gurobi (w/Presolve): ", result_gurobi[end].status, " time = ",result_gurobi[end].time )

    push!(result_gurobi_no_presolve,median([solve_gurobi(probdata;presolve=false, verbose = verbosity) for i = 1:K]))
    println("Result Gurobi (no/Presolve): ", result_gurobi_no_presolve[end].status, " time = ",result_gurobi_no_presolve[end].time )

    push!(result_gurobi_single_thread,median([solve_gurobi(probdata;presolve=false,threads=1,verbose = verbosity) for i = 1:K]))
    println("Result Gurobi (Single Thread): ", result_gurobi_single_thread[end].status, " time = ",result_gurobi_single_thread[end].time )

    push!(result_mosek,solve_mosek(probdata))
    println("Result Mosek: ", result_mosek[end].status, " time = ",result_mosek[end].time )

end

#Note objective function source file doesn't
#include underscores in problem names
refsols = get_ref_solutions(joinpath(@__DIR__,"ref_solutions.txt"))
no_underscore = x -> replace(x,"_" => "")

print_header()
for i = 1:length(result_ecos)
    objname = no_underscore(names[i])
    print_row(i, names[i], result_ecos[i],result_clarabel[i], refsols[objname].OPT)

end

jldsave("maros_run_all_new.jld2"; names,result_ecos,result_osqp,result_clarabel,result_clarabel_cholmod, result_gurobi, result_gurobi_no_presolve, result_gurobi_single_thread, result_mosek, refsols)
