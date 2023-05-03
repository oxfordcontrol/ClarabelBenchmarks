# Run benchmarks on Maros-Meszaros problems

# include any solvers you want to test 
using ClarabelBenchmarks, DataFrames, JLD2
using Clarabel, ClarabelRs,ECOS, Gurobi, MosekTools, OSQP

solvers = [Gurobi,MosekTools,Clarabel,ClarabelRs,ECOS,OSQP]

class = ["maros"]

#data will go here.  Only regenerated if the file is missing
filename = (@__FILE__) * ".jld2"

function run_tests(solvers)
    #outputs will be concatenated here 
    df = DataFrame()
    for package in solvers 
        println("Solving with ", package)
        settings = ClarabelBenchmarks.SOLVER_CONFIG[Symbol(package)]
        result = ClarabelBenchmarks.run_benchmarks(
            package.Optimizer; 
            settings = settings,
            class = class,
            verbose=false,
            precompile=true)
        df = [df;result]
    end
    df = sort(df,[:group, :problem])
    return df
end

#if !isfile(filename)
    df = run_tests(solvers)
    jldsave(filename; df)
#else
   # df = load(filename)
#end

