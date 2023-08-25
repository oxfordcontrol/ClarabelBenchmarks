# get the solver package as a Module 
task_id     = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
package_str = Base.parse(String, ENV["MODULE_NUMBER_" * task_id])
package     = eval(Meta.parse(module_name))

# get the benchmark suite target 
classkey    = Base.parse(String, ENV["CLASS_KEY" * task_id])

println("The package is ", package)
println("The  is ", classkey)