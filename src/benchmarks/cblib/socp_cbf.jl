using ConicBenchmarkUtilities
using Clarabel
using Mosek, MosekTools
using MathOptInterface, JuMP
const MOI = MathOptInterface


filelist = readdir(pwd()*"./targets/socp_cblib")
Socplist = String[]


for i in eachindex(filelist)
    datadir = filelist[i]
    println("Current file ", i, " is ", datadir)

    model = read_from_file("./targets/socp_cblib/"*datadir)
    set_optimizer(model, Clarabel.Optimizer)
    # set_optimizer(model, Mosek.Optimizer)
    # set_optimizer_attribute(model,"MSK_IPAR_PRESOLVE_USE", false)
    results = optimize!(model)
end

