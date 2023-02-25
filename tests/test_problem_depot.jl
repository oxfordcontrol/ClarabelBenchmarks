using Convex, Clarabel, Test
mymodel = []
myp = []
q = []
@testset "Clarabel" begin
    Convex.ProblemDepot.run_tests([r""]; exclude=[r"mip"]) do p
        model = Convex.MOI.OptimizerWithAttributes(Clarabel.Optimizer, "verbose" => true)
        solve!(p, model)
    end
end


