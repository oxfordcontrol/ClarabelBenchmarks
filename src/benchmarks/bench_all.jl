# Run all benchmarks

#Caution: this will take a very long time to run
include("bench_maros.jl")
include("bench_maros_shifted.jl")
include("bench_mpc.jl")
include("bench_sslsq.jl")
include("bench_cblib_exp.jl")
include("bench_cblib_socp.jl")
include("bench_cblib_pow.jl")
include("bench_netlib_feasible.jl")
include("bench_netlib_infeasible.jl")
include("bench_socp.jl")
include("bench_opf_lp.jl")
include("bench_opf_socp.jl")
include("bench_opf_sdp.jl")
include("bench_lp.jl")
include("bench_qp.jl")
include("bench_sdp.jl")