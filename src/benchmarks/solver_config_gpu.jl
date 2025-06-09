
# all benchmarks using this file for configuring 
# individual solvers:

SettingsDict  = Dict{Symbol,Any}
SOLVER_CONFIG_GPU = Dict{Symbol,SettingsDict}()

#---------------------------------------------

#Clarabel (Julia version )
SOLVER_CONFIG_GPU[:Clarabel] = SettingsDict(
    :max_iter               => 500,
    :tol_gap_abs            => 1e-6,
    :tol_gap_rel         => 1e-6,
    :tol_feas            => 1e-6,
    :tol_ktratio         => 1e-4,
)

#Clarabel (Julia version, on GPU)
SOLVER_CONFIG_GPU[Symbol("ClarabelBenchmarks.ClarabelGPU")] = SettingsDict(
    :direct_kkt_solver      => true,
    :direct_solve_method    => :cudss,
    :max_iter               => 500,
    :tol_gap_abs            => 1e-6,
    :tol_gap_rel         => 1e-6,
    :tol_feas            => 1e-6,
    :tol_ktratio         => 1e-4,
    :soc_threshold       => 50,         #for experiments of FEM models
)

#Clarabel (Rust version )
SOLVER_CONFIG_GPU[:ClarabelRs] = SettingsDict(
    :direct_kkt_solver      => true,
    :direct_solve_method => :faer,
    :max_iter               => 500,
    :tol_gap_abs            => 1e-6,
    :tol_gap_rel         => 1e-6,
    :tol_feas            => 1e-6,
    :tol_ktratio         => 1e-4,
)

#Clarabel (128 bit version )
SOLVER_CONFIG_GPU[Symbol("ClarabelBenchmarks.Clarabel128")] = SettingsDict(
    :max_iter => 500,	
)

#ECOS
SOLVER_CONFIG_GPU[:ECOS] = SettingsDict(
)

#MOSEK
SOLVER_CONFIG_GPU[:Mosek] = SettingsDict(
    :MSK_IPAR_PRESOLVE_USE => 0,
    :MSK_DPAR_INTPNT_CO_TOL_DFEAS => 1e-6,
    :MSK_DPAR_INTPNT_CO_TOL_MU_RED => 1e-6,
    :MSK_DPAR_INTPNT_CO_TOL_PFEAS => 1e-6,
    :MSK_DPAR_INTPNT_CO_TOL_REL_GAP => 1e-6,
)

#MOSEK no presolve
SOLVER_CONFIG_GPU[Symbol("ClarabelBenchmarks.MosekWithPresolve")] = SettingsDict(
    :MSK_DPAR_INTPNT_CO_TOL_DFEAS => 1e-6,
    :MSK_DPAR_INTPNT_CO_TOL_MU_RED => 1e-6,
    :MSK_DPAR_INTPNT_CO_TOL_PFEAS => 1e-6,
    :MSK_DPAR_INTPNT_CO_TOL_REL_GAP => 1e-6,
)

#Gurobi 
SOLVER_CONFIG_GPU[:Gurobi] = SettingsDict(
    :BarConvTol => 1e-6,
)

#OSQP
SOLVER_CONFIG_GPU[:OSQP] = SettingsDict(
    :eps_abs => 1e-5,
    :eps_rel => 1e-5,
)

#SCS
SOLVER_CONFIG_GPU[:SCS] = SettingsDict(
)

#HiGHS
SOLVER_CONFIG_GPU[:HiGHS] = SettingsDict(
    :presolve => "off"
)

#Hypatia
SOLVER_CONFIG_GPU[:Hypatia] = SettingsDict(
)

#Tulip
SOLVER_CONFIG_GPU[:Tulip] = SettingsDict(
    :Presolve_Level => 0
)