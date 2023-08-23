# Problem case taken from https://github.com/oxfordcontrol/Clarabel.jl/issues/103

@add_problem qp issue_103 function qp_issue_103(
    model,
)

    points1 = [
            [0.796, 0.768, 0.334], 
            [0.879, 0.227, 0.297],
        ]
    points2 = [
            [0.322, 0.079, 0.305], 
            [0.486, 0.145, 0.792], 
            [0.194, 0.999, 0.333],
        ]

    n1 = length(points1)
    n2 = length(points2)
    dims = length(points1[1])
    @assert length(points1[1])==length(points2[1])
    @variable(model, s[i = 1:n1] ≥ 0)
    @variable(model, t[i = 1:n2] ≥ 0)
    @constraint(model, sum(s[i] for i in 1:n1) == 1)
    @constraint(model, sum(t[i] for i in 1:n2) == 1)
    @expression(model, pt1[i = 1:dims], sum(s[j]*points1[j][i] for j in 1:n1))
    @expression(model, pt2[i = 1:dims], sum(t[j]*points2[j][i] for j in 1:n2))
    @expression(model, d[i = 1:dims], pt1[i]-pt2[i])
    @objective(model, Min, sum(d[i]*d[i] for i in 1:dims))
    optimize!(model)

end