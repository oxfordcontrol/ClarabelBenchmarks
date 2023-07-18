using MatrixDepot
using SparseArrays
using MAT
using Random
rand(0)

accepted_problems = ["least squares problem"]

# List all problems (Filter some)
list = mdlist("*/*")

# create target directory if needed 
ispath("targets") || mkdir("targets")

# Get matrix A and vector b for all problems
prob_count = 0
md_info = 0
for problem in list

    println("problem is ", problem)

    try
        global md_kind = mdinfo(problem).content[4].items[end][1].content[1]  # Nasty
    catch 
        continue
    end

    # Check if type is correct
    if split(md_kind)[1] == "kind:"  # Got the right kind
        kind = join(split(md_kind)[2:end], " ")
        if kind in accepted_problems
            md = mdopen(problem)
            MatrixDepot.addmetadata!(md.data)
            print("Name = $(md.data.name)\n")
            A = float(md.A)
            if issymmetric(A)
                print("Making it a generic matrix\n")
                A = SparseMatrixCSC(A)
            end
            global prob_count += 1
            print("Found $(kind) n = $(prob_count)\n")
            (m, n) = size(A)
            new_problem =  Dict("A" => A, "name" => md.data.name)
            try
                new_problem["b"] = float(md.b)
                print("Storing also b\n")
            catch e
                print("No field b. Creating random one.\n")
                s0 = randn(m)
                x0 = randn(n)
                b = A * x0 + s0
                new_problem["b"] = b
            end
            file_name = replace("$(md.data.name).mat", "/" => "_")
            file_name = joinpath("targets",file_name)
            try
                matwrite(file_name, new_problem)
            catch e
                print(e)
                break
            end
            
            print("Written to file $(file_name)\n")
        end
    else
        print("Wrong type extracted from metadata. Type = $(md_kind)\n")
    end
    
end

print("Total number of problems = $(prob_count)\n")
