#exclude files with more than this many nodes
#since the problem build times are very long.
#or the solve times are huge for most solvers .

MAX_POWER_MODEL_NODES = Dict{String,Int}()
MAX_POWER_MODEL_NODES["sdp"] = 1800 
MAX_POWER_MODEL_NODES["socp"] = 19000
MAX_POWER_MODEL_NODES["lp"] = typemax(Int)


function is_number_of_nodes_ok(testname,group)

    r = r"case[0-9]+" #regex to match case number + nodes 
    idx = findfirst(r,testname)
    nodes_str = testname[idx][5:end] #remove "case" prefix 
    nodes     = parse(Int,nodes_str) #convert to int 
    return nodes <= MAX_POWER_MODEL_NODES[group]

end 

function powermodels_get_test_names()

    # This will return a vector of (group,filename) pairs
    rootpath    = joinpath(@__DIR__,"pglib-opf/")
    paths       = readdir(rootpath)
    paths       = filter(!contains("."),paths)
    paths       = filter(!contains("LICENSE"),paths)
    
    # files appear in both subdirectories and the root directory
    push!(paths,"")

    #dict of test names and paths to test files
    tests = Dict()

    for path = paths
        srcpath = joinpath(rootpath,path)
        #gets the name of the data files in this group
        files = filter(endswith(".m"), readdir(srcpath))

        for f in files 
            key = String(split(f,".")[1])
            key = String(split(key,"pglib_opf_")[2])
            tests[key] = joinpath(rootpath,path,f)
        end
    end

    if length(tests) == 0
        error("No tests found in pglib-opf.   Did you remember to clone submodules?")
    end

    return tests
end

