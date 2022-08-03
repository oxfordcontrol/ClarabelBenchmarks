using JLD2, MathOptInterface, JuMP
using Plots

maxtime = 1000

Base.@kwdef mutable struct TestResult
    time::Float64
    status::MOI.TerminationStatusCode
    cost::Float64
end

data = load(joinpath(@__DIR__,"maros_run_all.jld2"))
n = length(data["result_clarabel"])
names = data["names"]

times = Dict{String,Vector{Float64}}()

nicenames =  Dict([
             ("ecos", "ECOS"),
             ("osqp", "OSQP"),
             ("mosek", "MOSEK"),
             ("clarabel_qdldl", "Clarabel (QDLDL)"),
             ("clarabel_cholmod", "Clarabel (CHOLMOD)"),
             ("clarabel_mkl", "Clarabel (MKL)"),
             ("gurobi", "Gurobi (w/presolve)"),
             ("gurobi_np", "Gurobi (multi-thread)"),
             ("gurobi_st", "Gurobi (1 thread)"),
             ]
             )


tags = ["clarabel_qdldl", "gurobi_st", "ecos", "mosek"] #"gurobi",

plottags = tags

#tags = ["ecos","clarabel_qdldl","clarabel_mkl","gurobi_np","gurobi_st"]




times["osqp"]  = [data["result_osqp"][i].time for i in 1:n]
times["ecos"]  = [data["result_ecos"][i].time for i in 1:n]
times["clarabel_qdldl"]  = [data["result_clarabel"][i].time for i in 1:n]
times["clarabel_cholmod"]  = [data["result_clarabel_cholmod"][i].time for i in 1:n]
#times["clarabel_mkl"]  = [data["result_clarabel_mkl"][i].time for i in 1:n]
times["gurobi"]  = [data["result_gurobi"][i].time for i in 1:n]
times["gurobi_np"]  = [data["result_gurobi_no_presolve"][i].time for i in 1:n]
times["gurobi_st"]  = [data["result_gurobi_single_thread"][i].time for i in 1:n]
times["mosek"]  = [data["result_mosek"][i].time for i in 1:n]

status = Dict{String,Vector{MOI.TerminationStatusCode}}()
status["osqp"]  = [data["result_osqp"][i].status for i in 1:n]
status["ecos"]  = [data["result_ecos"][i].status for i in 1:n]
status["clarabel_qdldl"]  = [data["result_clarabel"][i].status for i in 1:n]
status["clarabel_cholmod"]  = [data["result_clarabel_cholmod"][i].status for i in 1:n]
#status["clarabel_mkl"]  = [data["result_clarabel_mkl"][i].status for i in 1:n]
status["gurobi"]  = [data["result_gurobi"][i].status for i in 1:n]
status["gurobi_np"]  = [data["result_gurobi_no_presolve"][i].status for i in 1:n]
status["gurobi_st"]  = [data["result_gurobi_single_thread"][i].status for i in 1:n]
status["mosek"]  = [data["result_mosek"][i].status for i in 1:n]


#----------------------
#performance plot

#gather up the dimensions
refsols = data["refsols"]
no_underscore = x -> replace(x,"_" => "")
M = [refsols[no_underscore(name)].M for name = data["names"]]
N = [refsols[no_underscore(name)].N for name = data["names"]]
QNZ = [refsols[no_underscore(name)].QNZ for name = data["names"]]
density = QNZ./(N.^2)

#find the best times
besttime = ones(n)
for i = 1:n
    t = 1e5
    for tag in tags
        tagt = times[tag][i]
        t = Base.min(tagt,t)
        println(t)
    end
    besttime[i] = t
end

#terrible score if you couldn't solve it
for tag in tags
    times[tag][status[tag] .!= MOI.OPTIMAL] .= maxtime
    times[tag][isnan.(times[tag])] .= maxtime
end

pratio = deepcopy(times)

#normalize the times
for tag in tags
    pratio[tag] ./= besttime
end

perf_levels = (10.).^(0:0.01:3)

p1 = plot()
#make a plot
for tag in plottags
    t = pratio[tag][N .>= 0]
    y = [sum(t .< p)/n for p in perf_levels]
    plot!(p1, perf_levels,y,label = nicenames[tag], palette = :Set1_9, linewidth = 2)
end

xaxis!(p1, :log10)
plot!(p1,
      titlefontsize = 8,
      xlabelfontsize = 8,
      ylabelfontsize = 8,
      legendfontsize = 6,
      xlims=[1,1000],
      ylims=[0,1.],
      xticks=[1,10,100,1000],
      yticks=0.0:0.2:1.0,
      minorgrid=true,
      legend_position = :bottomright,
      title  = "Performance Ratio - Single Threaded",
      xlabel = "Performance Ratio",
      ylabel = "Ratio of problems Solved",
     )

display(p1)
Plots.pdf(p1,"Performance Plots-Single Thread")

#scatter plot

#comment out to get the same tags as the performance plot
#tags = ["ecos","clarabel_qdldl","clarabel_cholmod","gurobi_np","gurobi_st","mosek"] #"gurobi",
#plottags = ["clarabel_qdldl", "clarabel_cholmod", "ecos","gurobi_st","mosek"]

p2 = plot()
yaxis!(p2, :log10)
p = sortperm(times["clarabel_qdldl"])

#make a plot
shifts = 1 .+ 2*(0:length(plottags))./10
x = 1:n
for j in 1:length(plottags)
    tag = plottags[j]
    t = times[tag][p]
    t[t .== 1e3 ] .*= shifts[j]
    plot!(p2, x,t,label = nicenames[tag],seriestype = :scatter,markersize = 4,palette = :Set1_9)
end
annotate!(-6, 10^3, Plots.text("Fail", :right, 8))
plot!(p2,
      titlefontsize = 8,
      xlabelfontsize = 8,
      ylabelfontsize = 8,
      legendfontsize = 6,
      ylims=[1e-4,1e3],
      yticks=(10.).^collect(-4:2.),  #no tick at the top, "Fail" instead
      minorgrid=true,
      legend_position = :bottomright,
      title  = "Solve Times - Single Threaded",
      xlabel = "Problem Number",
      ylabel = "Solve Time",
     )

display(p2)

Plots.pdf(p2,"Solve Times-Single Thread")
