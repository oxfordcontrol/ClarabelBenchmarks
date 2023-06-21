using MAT 

function netlib_feasible_get_test_names()

    srcpath = joinpath(@__DIR__,"./feasibleLP")
    #get Maros archive path and get names of data files
    files = filter(endswith(".mat"), readdir(srcpath))
    return [splitext(f)[1] for f in files]

end

function netlib_feasible_load(test_name)

    srcpath = joinpath(@__DIR__,"./feasibleLP")
    file = joinpath(srcpath,test_name * ".mat")
    probdata = matread(file)
    conic_data = NETLIButils.data_conic_form(probdata)

    return conic_data
end

function netlib_infeasible_get_test_names()

    srcpath = joinpath(@__DIR__,"./infeasibleLP")
    #get Maros archive path and get names of data files
    files = filter(endswith(".mat"), readdir(srcpath))
    return [splitext(f)[1] for f in files]

end

function netlib_infeasible_load(test_name)

    srcpath = joinpath(@__DIR__,"./infeasibleLP")
    file = joinpath(srcpath,test_name * ".mat")
    probdata = matread(file)
    conic_data = NETLIButils.data_infeasible_conic_form(probdata)

    return conic_data
end


module NETLIButils 

    using ClarabelBenchmarks, SparseArrays

    # LP form
    #   min     c'x
    # s.t.      Ax = b
    #         l ≤ x ≤ u
    function data_lp_form(vars)

        A = vars["A"]
        b = vars["b"][:]
        l = vars["lo"][:]
        u = vars["hi"][:]
        c = vars["c"][:]

        return c,b,A,l,u
    end

    function data_infeasible_lp_form(vars)

        vars = vars["Problem"]
        A = vars["A"]
        b = vars["b"][:]
        l = vars["lo"][:]
        u = vars["hi"][:]
        c = vars["c"][:]

        return c,b,A,l,u
    end

    function data_conic_form(vars)

        c,b,A,l,u = data_lp_form(vars)
        n = size(A,2)

        #separate into equalities and inequalities
        Ai = spdiagm(0 => ones(n))
        eqidx = l .== u
        Aeq = [A; Ai[eqidx,:]]
        beq = [b; l[eqidx]]

        #make into single constraint
        Aineq = Ai[.!eqidx,:]
        lineq = l[.!eqidx,:]
        uineq = u[.!eqidx,:]
        Aineq = [Aineq; -Aineq]
        bineq = [uineq;-lineq]
        Aineq,bineq = ClarabelBenchmarks.dropinfs(Aineq,bineq)

        return c,Aineq,bineq,Aeq,beq

    end

    function data_infeasible_conic_form(vars)

        c,b,A,l,u = data_infeasible_lp_form(vars)
        n = size(A,2)

        #separate into equalities and inequalities
        Ai = spdiagm(0 => ones(n))
        eqidx = l .== u
        Aeq = [A; Ai[eqidx,:]]
        beq = [b; l[eqidx]]

        #make into single constraint
        Aineq = Ai[.!eqidx,:]
        lineq = l[.!eqidx,:]
        uineq = u[.!eqidx,:]
        Aineq = [Aineq; -Aineq]
        bineq = [uineq;-lineq]
        Aineq,bineq = dropinfs(Aineq,bineq; thresh = 5e19)

        return c,Aineq,bineq,Aeq,beq

    end

end #module