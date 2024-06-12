# Run all GPU benchmarks

#Caution: this will take a very long time to run
include("bench_netlib_feasible_gpu.jl")
include("bench_qp_gpu.jl")
include("bench_opf_lp_gpu.jl")
include("bench_opf_socp_gpu.jl")
include("bench_cblib_socp_gpu.jl")
include("bench_cblib_exp_gpu.jl")
include("bench_cblib_pow_gpu.jl")
include("bench_mittelmann_gpu.jl")