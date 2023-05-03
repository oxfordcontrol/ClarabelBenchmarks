# Example script for running the tests in this repo 
# include any solvers you want to test 
using Clarabel, ClarabelBenchmarks, ECOS, DataFrames

# define the problem classes you want to solve.  
# Default is everything. Regex works here.
#
# You can see the available classes using 
# >> print(keys(ClarabelBenchmarks.PROBLEMS))

class = ["lp","socp"]

# name specific tests to exclude regardless of 
# the class.   Regex works here.
exclude=[r"sdp_options", r"dummy"]

#to compare solvers, make a DataFrame here and 
#then concatenate the results 
df = DataFrame()

#solve the problems in the benchmark group 
#for a particular solver.   

result = ClarabelBenchmarks.run_benchmarks(
    Clarabel.Optimizer; 
    class = class,verbose=true,
    exclude=exclude)

df = [df;result]

# you can also pass solver-specific settings 
# to the solvers 
settings = Dict(
            :max_iter => 100, 
            #other options...
            )

result = ClarabelBenchmarks.run_benchmarks(
    ECOS.Optimizer; 
    class = class,
    settings = settings,
    verbose=true,
    exclude=exclude)

df = [df;result]
            
# manipulate the results for comparison, e.g.
# first by group and then by problem name so 
# that solver results from the same problem are 
# adjacent in the table
df = sort(df,[:group, :problem])
print(df) 