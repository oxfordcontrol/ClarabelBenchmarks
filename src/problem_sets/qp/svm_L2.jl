# Huber fitting.   Uses reformulation at https://osqp.org/docs/examples/huber.html
#SVM with quadratic penality

#From : https://osqp.org/docs/examples/svm.html


using Random

function qp_svm_L2(model::GenericModel{T}, n) where{T}

    rng = Random.MersenneTwister(271324 + n)

    #Generate problem data
    m = 50 * n;
    N = ceil(Int,m/2);
    gamma = 1;
    A_upp = sprandn(rng, T, N, n, 0.2);
    A_low = sprandn(rng, T, N, n, 0.2);

    Ad = [A_upp ./ sqrt(n) .+ (A_upp .!= 0) ./ n;
          A_low ./ sqrt(n) .- (A_low .!= 0) ./ n];
    b = [ones(N); -ones(N)];

    @variable(model, x[1:n])
    @variable(model, t[1:(2*N)] >= 0)
    @constraint(model, t .>= Diagonal(b)Ad*x .+ 1. )
    @objective(model, Min, T(0.5)*dot(x,x) + gamma * ones(T,2*N)'*t)

end


#generate problems according to problem type and size 

for n in [10, 100, 500]

    group_name = "qp"
    test_name  = "svm_L2_n_" * string(n)
    fcn_name   = Symbol(group_name * "_" * test_name )

    @eval begin
        @add_problem $group_name $test_name function $fcn_name(
            model; kwargs...
        )
            return solve_generic(qp_svm_L2,model,$n; kwargs...)
        end
    end
end




