

using ClarabelBenchmarks
using Clarabel, ClarabelRs

# get the solver package as a Module 
task_id     = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
package_str = ENV["MODULE_NUMBER_" * string(task_id)]
package     = eval(Meta.parse(package_str))

# get the benchmark suite target 
classkey    = ENV["BENCHMARK_CLASS_KEY"]

#max solve time per problem
time_limit     = Base.parse(Int, ENV["BENCHMARK_PROBLEM_TIME_LIMIT"])
time_limit     = Float64(time_limit)

ClarabelBenchmarks.run_benchmark!(package, classkey; 
               time_limit = time_limit, 
               verbose = false
	       )
	       