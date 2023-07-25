function mpc_solve_problem(
    model,
    problem
)
    data = mpc_load(problem)

    #problem data as in Kouzoupis, eq(1)
    x0 = data["x0"]
    xNr = data["xNr"]
    A = data["A"]
    B = data["B"]
    e = data["e"]
    f = data["f"]
    C = data["C"]
    D = data["D"] 
    M = data["M"]
    N = data["N"]
    T = data["T"]
    yr = data["yr"]
    ur = data["ur"]
    ymin = data["ymin"]
    ymax = data["ymax"]
    umin = data["umin"]
    umax = data["umax"]
    dmin = data["dmin"]
    dmax = data["dmax"]
    dNmin = data["dNmin"]
    dNmax = data["dNmax"]
    Q = data["Q"]
    R = data["R"]
    S = data["S"]
    P = data["P"]

    #does the problem have outputs?
    has_outputs = !isnothing(C)

    #problem dimensions 
    ni = data["ni"]
    nx = size(A,2)
    nu = size(B,2)

    @variable(model, x[1:nx,1:ni+1])
    @variable(model, u[1:nu,1:ni])

    if has_outputs
        ny = size(C,1)
        @variable(model, y[1:ny,1:ni])
    end

    # dynamics and outputs
    @constraint(model, x[:,1] .== x0)
    A = sparse(A); B = sparse(B)
    for i in 1:ni
        @constraint(model, x[:,i+1] .== A*x[:,i] + B*u[:,i] + f)

    end 

    if has_outputs 
        C = sparse(C); 
        if isnothing(D)
            D = sparse(zeros(size(C,1),size(B,2)))
        end
        for i in 1:ni
            @constraint(model, y[:,i] .== C*x[:,i] + D*u[:,i] + e)
        end 
    end

    # interval constraints 
    if !isnothing(umin)
        for i in 1:ni
            @constraint(model, umin .<= u[:,i] .<= umax)
        end 
    end

    if has_outputs && !isnothing(ymin)
        for i in 1:ni
            @constraint(model, ymin .<= y[:,i] .<= ymax)
        end
    end

    if has_outputs && !isnothing(dmin)
        M = sparse(M)
        for i in 1:ni
            @constraint(model, dmin .<= M*y[:,i] + N*u[:,i] .<= dmax)
        end
    end

    #terminal constraints 
    if !isnothing(dNmin)
        T = sparse(T)
        @constraint(model, dNmin .<= T*x[:,ni+1] .<= dNmax)
    end

    #objectives 
    Q = sparse(Q); R = sparse(R)
    if isnothing(S)
        QQ = SparseArrays.blockdiag(Q,R)
    else
        QQ = sparse([Q S;S' R])
    end 

    #ensure references exist (zero if needed)
    if has_outputs && (isnothing(yr) || yr == 0.0)
        yr = zeros(size(y))
    end
    if (isnothing(ur) || ur == 0.0)
        ur = zeros(size(u))
    end

    
    objective = 0
    for i in 1:ni

        if has_outputs
            v = [y[:,i]-yr[:,i];u[:,i]-ur[:,i]]
        else
            v = [x[:,i]; u[:,i]-ur[:,i]]
        end

        objective += v'*QQ*v
    end

    if !isnothing(P)
        P = sparse(P)
        objective += x[:,ni]'*P*x[:,ni]
    end

    @objective(model, Min, objective)



    optimize!(model)

    return nothing

end



# MPC problems 
for test_name in mpc_get_test_names()
    fcn_name = Symbol("mpc_" * test_name)
    @eval begin
            @add_problem mpc function $fcn_name(
                model,
            )
                return mpc_solve_problem(model,$test_name)
            end
    end
end 

