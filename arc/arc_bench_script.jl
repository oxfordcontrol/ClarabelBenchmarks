

using ClarabelBenchmarks
using Dates

println("Start time : ", Dates.now())
println()

# get the solver package as a string 
task_id     = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
package_str = ENV["MODULE_NUMBER_" * string(task_id)]


#load this package.  Special treatment for Mosek since
#its package isn't the same name as the solver 
if package_str == "Mosek"
   using MosekTools
else 
   eval(Meta.parse("using " * package_str))
end 

#make into a variable of type Module
package = eval(Meta.parse(package_str))

# get the benchmark suite target 
classkey    = ENV["BENCHMARK_CLASS_KEY"]

#max solve time per problem
time_limit     = Base.parse(Int, ENV["BENCHMARK_PROBLEM_TIME_LIMIT"])
time_limit     = Float64(time_limit)

ClarabelBenchmarks.run_benchmark!(package, classkey; 
               time_limit = time_limit, 
               verbose = false
	       )

println("\n\nFinish time : ", Dates.now())