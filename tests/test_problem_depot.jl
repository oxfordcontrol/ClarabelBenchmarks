using Convex, Clarabel, Test
solver = Clarabel

@testset "Clarabel" begin
    Convex.ProblemDepot.run_tests([r""]; exclude=[r"mip",r"sdp"]) do p
        model = Convex.MOI.OptimizerWithAttributes(solver.Optimizer, "verbose" => true)
        solve!(p, model)
    end
end


