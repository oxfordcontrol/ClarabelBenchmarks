module ClarabelBenchmarks

    # main test function and problem def macros live here 
    include("./main.jl")

    #fake problems for compiler warmup 
    include("./benchmarks/dummy.jl")

    #add new categories and problems here
    include("./benchmarks/maros/include.jl")
    include("./benchmarks/netlib/include.jl")
    include("./benchmarks/cblib/include.jl")
    include("./benchmarks/lp/include.jl")
    include("./benchmarks/qp/include.jl")
    include("./benchmarks/socp/include.jl")
    include("./benchmarks/sos/include.jl")
    
end 

