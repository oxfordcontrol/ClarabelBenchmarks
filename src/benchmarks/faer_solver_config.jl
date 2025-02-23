
# all benchmarks using this file for configuring 
# individual solvers:

SettingsDict  = Dict{Symbol,Any}
SOLVER_CONFIG = Dict{Symbol,SettingsDict}()

#---------------------------------------------

#Clarabel (Julia version )
SOLVER_CONFIG[:Clarabel] = SettingsDict(
)

#Clarabel (Rust version )
SOLVER_CONFIG[:ClarabelRs] = SOLVER_CONFIG[:Clarabel]
SOLVER_CONFIG[:ClarabelRs] = SettingsDict(
    :direct_solve_method => :faer,
)

#Clarabel (Julia version, no quadratics )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelHSDE")] = deepcopy(SOLVER_CONFIG[:Clarabel])
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabeHSDE")][:use_quad_obj] = false

#Clarabel (Rust version, no quadratics )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelRsHSDE")] = deepcopy(SOLVER_CONFIG[:ClarabelRs])
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelRsHSDE")][:use_quad_obj] = false

#Clarabel (128 bit version )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.Clarabel128")] = SettingsDict(
    :max_iter => 500,	
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