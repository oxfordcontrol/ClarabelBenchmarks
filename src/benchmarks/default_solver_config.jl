# all benchmarks using this file for configuring 
# individual solvers:

SettingsDict  = Dict{Symbol,Any}
SOLVER_CONFIG = Dict{Symbol,SettingsDict}()

#---------------------------------------------

#Clarabel (Julia version )
SOLVER_CONFIG[:Clarabel] = SettingsDict(
    #:iterative_refinement_reltol => 1e-11,
    #:iterative_refinement_abstol => 1e-10,
    #:static_regularization_constant => 1e-9,
)

#Clarabel (Rust version )
SOLVER_CONFIG[:ClarabelRs] = SOLVER_CONFIG[:Clarabel]
# SOLVER_CONFIG[:ClarabelRs] = SettingsDict(
# )

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