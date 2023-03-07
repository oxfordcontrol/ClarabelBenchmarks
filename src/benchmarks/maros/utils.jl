using MAT 

function maros_get_test_names()

    srcpath = joinpath(@__DIR__,"targets/mat")
    #get Maros archive path and get names of data files
    files = filter(endswith(".mat"), readdir(srcpath))
    return [splitext(f)[1] for f in files]

end

function maros_load(test_name)

    srcpath = joinpath(@__DIR__,"targets/mat")
    file = joinpath(srcpath,test_name * ".mat")
    probdata = matread(file)
    conic_data = MAROSutils.data_conic_form(probdata)

    return conic_data
end


module MAROSutils

    function dropinfs(A,b)

        b = b[:]
        finidx = abs.(b) .< 1e20 * (1-eps(Float64))
        #b = b[finidx]
        #A = A[finidx,:]
        #println("Dropping ", sum(.!finidx))
        return A,b

    end

    function data_osqp_form(vars)

        n = Int(vars["n"])
        m = Int(vars["m"])
        A   = vars["A"]
        P   = vars["P"]
        c   = vars["q"][:]
        c0  = vars["r"]
        l   = vars["l"][:]
        u   = vars["u"][:]

        #force a true double transpose
        #to ensure data is sorted within columns
        A = (A'.*1)'.*1
        P = (P'.*1)'.*1

        return P,c,A,l,u
    end

    function data_conic_form(vars)

        P,c,A,l,u = data_osqp_form(vars)

        #separate into equalities and inequalities
        eqidx = l .== u
        Aeq = A[eqidx,:]
        beq = l[eqidx]

        #make into single constraint
        Aineq = A[.!eqidx,:]
        lineq = l[.!eqidx,:]
        uineq = u[.!eqidx,:]
        Aineq = [Aineq; -Aineq]
        bineq = [uineq;-lineq]
        Aineq,bineq = dropinfs(Aineq,bineq)

        return P,c,Aineq,bineq,Aeq,beq

    end

end #end module