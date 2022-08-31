using JLD2, MathOptInterface, JuMP
using Plots, StatsPlots, Printf

#bar

QNZ = [refsols[no_underscore(name)].QNZ for name = data["names"]]
M = [refsols[no_underscore(name)].M for name = data["names"]]
N = [refsols[no_underscore(name)].N for name = data["names"]]
density = QNZ./(N.^2)

#this is the 5 problems bigger than N=5 with the densest P
bigidx = findall((density .>= 0.1) .& (N .> 2.)  .& (M .> 2.))
#bigidx = findall((density .>= 0.2))
#bigidx = bigidx[[4,1,2,3,5]]  #sorts small to mmarge nnz(P)

tags = ["ecos","clarabel_qdldl","clarabel_mkl","gurobi_np","gurobi_st", "mosek"] #"gurobi",
plottags = ["clarabel_qdldl", "gurobi_st", "gurobi_np", "ecos", "mosek"]

#make a plot
tbaseline = times["clarabel_qdldl"][bigidx]

M = zeros(length(bigidx),length(plottags))
for j in 1:length(plottags)
    tag = plottags[j]
    t = times[tag][bigidx]
    t[t .>= 1e3] .= 0
    t = t ./ tbaseline
    println(t)
    M[:,j] = t
end

xnames = [@sprintf("%s\nnnz(P)=%i\nN=%i\nM=%i", names[i],refsols[names[i]].QNZ,refsols[names[i]].N,refsols[names[i]].M) for i in bigidx]
ctg = repeat([nicenames[tag] for tag in plottags], inner = length(bigidx))
nam = repeat(names[bigidx], outer = length(plottags))
nam = repeat(xnames, outer = length(plottags))


p3 = groupedbar(nam, M, group = ctg, ylabel = "Relative solve time",
        title = "Relative solve times: nnz(P)/numel(P) > 0.1, (M,N) > 2", bar_width = 0.4,
        lw = 0, framestyle = :box,legend_position = :topright,
        titlefontsize = 6,
        xlabelfontsize = 6,
        ylabelfontsize = 6,
        legendfontsize = 6,
        fontsize = 6,
        annotationfontsize = 4,
        tickfontsize = 6
)

plot!(p3,
        titlefontsize = 8,
        xlabelfontsize = 6,
        ylabelfontsize = 6,
        legendfontsize = 6,
        fontsize = 6,
        tickfontsize =6
)

Plots.pdf(p3,"Dense Objectives-Multithreaded")

display(p3)


# ctgex = repeat(["Category 1", "Category 2"], inner = 5)
# namex = repeat("G" .* string.(1:5), outer = 2)
#
# groupedbar(namex, rand(5, 2), group = ctgex, xlabel = "Groups", ylabel = "Scores",
#         title = "Scores by group and category", bar_width = 0.67,
#         lw = 0, framestyle = :box)
