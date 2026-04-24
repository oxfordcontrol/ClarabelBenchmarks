
# all benchmarks using this file for configuring 
# individual solvers:

SettingsDict = Dict{Symbol,Any}
SOLVER_CONFIG = Dict{Symbol,SettingsDict}()

#---------------------------------------------

# using Pardiso   #commented out since otherwise it will always be used 
ENV["OMP_NUM_THREADS"] = "16"
ENV["PARDISO_PATH"] = "~/software/panua/lib/"
ENV["MKL_PARDISO_PATH"] = "/opt/intel/oneapi/mkl/latest/lib/"


#Clarabel (Julia version )
SOLVER_CONFIG[:Clarabel] = SettingsDict(
    :max_threads => 1,
    :direct_solve_method => :auto,
)

#Clarabel (Rust version )
SOLVER_CONFIG[:ClarabelRs] = SOLVER_CONFIG[:Clarabel]

#Clarabel (Julia version, no quadratics )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelHSDE")] = deepcopy(SOLVER_CONFIG[:Clarabel])
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelHSDE")][:use_quad_obj] = false

#Clarabel (Rust version, no quadratics )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelRsHSDE")] = deepcopy(SOLVER_CONFIG[:ClarabelRs])
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelRsHSDE")][:use_quad_obj] = false

#Clarabel (128 bit version )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.Clarabel128")] = SettingsDict(
    :max_iter => 500,
)

#Clarabel (Julia version, no chordal )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelNonchordal")] = deepcopy(SOLVER_CONFIG[:Clarabel])
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelNonchordal")][:chordal_decomposition_enable] = false

#Clarabel (Rust version, no chordal )
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelRsNonchordal")] = deepcopy(SOLVER_CONFIG[:ClarabelRs])
SOLVER_CONFIG[Symbol("ClarabelBenchmarks.ClarabelRsNonchordal")][:chordal_decomposition_enable] = false


#ECOS
SOLVER_CONFIG[:ECOS] = SettingsDict(
)

#MOSEK
SOLVER_CONFIG[:Mosek] = SettingsDict(
    :MSK_IPAR_PRESOLVE_USE => 0,
    :MSK_IPAR_NUM_THREADS => 1,
)

#Gurobi 
SOLVER_CONFIG[:Gurobi] = SettingsDict(
    :presolve => false,
    :Threads => 1,
    :Method => 2,   #barrier method always
    :Crossover => 0 #crossover disabled always
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
    :presolve => "off",
    :threads => 1,
    :run_crossover => "off",
    #:solver = "ipm"
)

#Hypatia
SOLVER_CONFIG[:Hypatia] = SettingsDict(
)

#Tulip
SOLVER_CONFIG[:Tulip] = SettingsDict(
    :Presolve_Level => 0
)

#SeDuMi
SOLVER_CONFIG[:SeDuMi] = SettingsDict(
)

#SDPT3
SOLVER_CONFIG[:SDPT3] = SettingsDict(
)