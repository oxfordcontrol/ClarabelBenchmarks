# all benchmarks using this file for configuring 
# individual solvers:

SettingsDict  = Dict{Symbol,Any}
SOLVER_CONFIG = Dict{Symbol,SettingsDict}()

#---------------------------------------------

#Clarabel (Julia version )
SOLVER_CONFIG[:Clarabel] = SettingsDict(
    #:direct_solve_method => :hsl_ma57
)

#Clarabel (Rust version )
SOLVER_CONFIG[:ClarabelRs] = SettingsDict(
)

#ECOS
SOLVER_CONFIG[:ECOS] = SettingsDict(
)

#MOSEK
SOLVER_CONFIG[:Mosek] = SettingsDict(
    :MSK_IPAR_PRESOLVE_USE => 0
)

#Gurobi 
SOLVER_CONFIG[:Gurobi] = SettingsDict(
    :presolve => false,
)

#OSQP
SOLVER_CONFIG[:OSQP] = SettingsDict(
    :eps_abs => 1e-5,
    :eps_rel => 1e-5,
)

#SCS
SOLVER_CONFIG[:SCS] = SettingsDict(
)

#HiGHS
SOLVER_CONFIG[:HiGHS] = SettingsDict(
    :presolve => "off"
)

#Hypatia
SOLVER_CONFIG[:Hypatia] = SettingsDict(
)

#Tulip
SOLVER_CONFIG[:Tulip] = SettingsDict(
    :Presolve_Level => 0
)