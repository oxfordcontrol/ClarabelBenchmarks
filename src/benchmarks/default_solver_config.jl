# all benchmarks using this file for configuring 
# individual solvers:

SettingsDict  = Dict{Symbol,Any}
SOLVER_CONFIG = Dict{Symbol,SettingsDict}()

#---------------------------------------------

#Clarabel (Julia version )
SOLVER_CONFIG[:Clarabel] = SettingsDict(
)

#Clarabel (Julia version )
SOLVER_CONFIG[:ClarabelRs] = SettingsDict(
)

#Gurobi 
SOLVER_CONFIG[:Gurobi] = SettingsDict(
    :presolve => false,
    :threads => 1,
)

#ECOS
SOLVER_CONFIG[:ECOS] = SettingsDict(
)

#MOSEK
SOLVER_CONFIG[:MosekTools] = SettingsDict(
)

#OSQP
SOLVER_CONFIG[:OSQP] = SettingsDict(
)

#SCS
SOLVER_CONFIG[:SCS] = SettingsDict(
)

