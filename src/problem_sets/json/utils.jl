using JuMP, MathOptInterface, SparseArrays, LinearAlgebra

struct JsonConeSpec
    kind::Symbol
    dim::Int
    rowdim::Int
end

struct JsonProblemData{T}
    P::SparseMatrixCSC{T,Int}
    q::Vector{T}
    AT::SparseMatrixCSC{T,Int}
    b::Vector{T}
    cones::Vector{JsonConeSpec}
end

function json_get_test_names()
    targets_path = joinpath(@__DIR__, "targets")
    files = sort(filter(endswith(".json"), readdir(targets_path)))
    return [splitext(file)[1] for file in files]
end

json_target_path(test_name) = joinpath(@__DIR__, "targets", test_name * ".json")

json_triangle_number(dim::Integer) = dim * (dim + 1) ÷ 2

function json_parse_vector(data, ::Type{T}) where {T}
    values = Vector{T}(undef, length(data))
    @inbounds for i in eachindex(data)
        values[i] = T(data[i])
    end
    return values
end

function json_parse_sparse_matrix(data, ::Type{T}) where {T}
    raw_colptr = data["colptr"]
    raw_rowval = data["rowval"]
    raw_nzval = data["nzval"]
    n = Int(data["n"])

    colptr = Vector{Int}(undef, n + 1)
    rowval = Vector{Int}(undef, length(raw_rowval))
    nzval = Vector{T}(undef, length(raw_nzval))

    colptr[1] = 1
    nnz = 0

    @inbounds for col in 1:n
        start_idx = Int(raw_colptr[col]) + 1
        stop_idx = Int(raw_colptr[col + 1])

        for idx in start_idx:stop_idx
            value = T(raw_nzval[idx])
            if !iszero(value)
                nnz += 1
                rowval[nnz] = Int(raw_rowval[idx]) + 1
                nzval[nnz] = value
            end
        end

        colptr[col + 1] = nnz + 1
    end

    resize!(rowval, nnz)
    resize!(nzval, nnz)

    return SparseMatrixCSC(
        Int(data["m"]),
        n,
        colptr,
        rowval,
        nzval,
    )
end

function json_parse_cones(cone_data, test_name)
    cones = JsonConeSpec[]
    total_rows = 0

    for cone in cone_data
        key = Symbol(only(keys(cone)))
        value = cone[String(key)]

        spec = if key == :ZeroConeT
            dim = Int(value)
            JsonConeSpec(key, dim, dim)
        elseif key == :NonnegativeConeT
            dim = Int(value)
            JsonConeSpec(key, dim, dim)
        elseif key == :SecondOrderConeT
            dim = Int(value)
            JsonConeSpec(key, dim, dim)
        elseif key == :PSDTriangleConeT
            dim = Int(value)
            JsonConeSpec(key, dim, json_triangle_number(dim))
        else
            error(
                "Unsupported cone type $(String(key)) in JSON problem " *
                "$(test_name). Supported cones are ZeroConeT, " *
                "NonnegativeConeT, SecondOrderConeT, and PSDTriangleConeT.",
            )
        end

        spec.dim < 0 && error("Negative cone dimension in JSON problem $(test_name).")
        spec.rowdim < 0 && error("Negative cone block size in JSON problem $(test_name).")

        push!(cones, spec)
        total_rows += spec.rowdim
    end

    return cones, total_rows
end

function json_load_data(test_name, ::Type{T}) where {T}
    file = json_target_path(test_name)
    raw = open(file, "r") do io
        Clarabel.JSON.parse(read(io, String))
    end

    P = json_parse_sparse_matrix(raw["P"], T)
    q = json_parse_vector(raw["q"], T)
    A = json_parse_sparse_matrix(raw["A"], T)
    b = json_parse_vector(raw["b"], T)
    cones, cone_rows = json_parse_cones(raw["cones"], test_name)

    size(P, 1) == size(P, 2) || error("P must be square in JSON problem $(test_name).")
    size(P, 2) == length(q) || error("P and q size mismatch in JSON problem $(test_name).")
    size(A, 2) == length(q) || error("A and q size mismatch in JSON problem $(test_name).")
    size(A, 1) == length(b) || error("A and b size mismatch in JSON problem $(test_name).")
    cone_rows == length(b) || error("Cone dimensions do not match b in JSON problem $(test_name).")

    return JsonProblemData{T}(P, q, SparseMatrixCSC(transpose(A)), b, cones)
end

function json_cone_set(cone::JsonConeSpec)
    if cone.kind == :ZeroConeT
        return MOI.Zeros(cone.dim)
    elseif cone.kind == :NonnegativeConeT
        return MOI.Nonnegatives(cone.dim)
    elseif cone.kind == :SecondOrderConeT
        return MOI.SecondOrderCone(cone.dim)
    elseif cone.kind == :PSDTriangleConeT
        return MOI.Scaled(MOI.PositiveSemidefiniteConeTriangle(cone.dim))
    end

    error("Internal error: unsupported cone $(cone.kind).")
end

function json_make_cone_function(
    AT::SparseMatrixCSC{T,Int},
    x_indices::Vector{MOI.VariableIndex},
    b::Vector{T},
    row_start::Int,
    cone::JsonConeSpec,
) where {T}
    row_stop = row_start + cone.rowdim - 1
    nnz = 0

    @inbounds for row in row_start:row_stop
        nnz += AT.colptr[row + 1] - AT.colptr[row]
    end

    terms = Vector{MOI.VectorAffineTerm{T}}(undef, nnz)
    term_idx = 0
    local_row = 0

    @inbounds for row in row_start:row_stop
        local_row += 1
        for idx in AT.colptr[row]:(AT.colptr[row + 1] - 1)
            term_idx += 1
            terms[term_idx] = MOI.VectorAffineTerm(
                local_row,
                MOI.ScalarAffineTerm(-AT.nzval[idx], x_indices[AT.rowval[idx]]),
            )
        end
    end

    constants = copy(@view b[row_start:row_stop])
    return MOI.VectorAffineFunction(terms, constants)
end

function json_set_objective(
    model::GenericModel{T},
    x,
    x_indices::Vector{MOI.VariableIndex},
    P::SparseMatrixCSC{T,Int},
    q::Vector{T},
) where {T}
    if nnz(P) == 0
        linear_terms = Vector{MOI.ScalarAffineTerm{T}}(undef, length(q))
        term_idx = 0

        @inbounds for i in eachindex(q)
            coeff = q[i]
            if !iszero(coeff)
                term_idx += 1
                linear_terms[term_idx] = MOI.ScalarAffineTerm(coeff, x_indices[i])
            end
        end

        resize!(linear_terms, term_idx)
        objective = MOI.ScalarAffineFunction(linear_terms, zero(T))
        backend = JuMP.backend(model)
        MOI.set(backend, MOI.ObjectiveSense(), MOI.MIN_SENSE)
        MOI.set(backend, MOI.ObjectiveFunction{typeof(objective)}(), objective)
    else
        @objective(model, Min, dot(q, x) + T(1 / 2) * x' * Symmetric(P, :U) * x)
    end

    return nothing
end

function json_load(model::GenericModel{T}, test_name) where {T}
    data = json_load_data(test_name, T)

    @variable(model, x[1:length(data.q)])
    x_indices = JuMP.index.(x)
    json_set_objective(model, x, x_indices, data.P, data.q)
    backend = JuMP.backend(model)

    row_start = 1
    for cone in data.cones
        if cone.rowdim == 0
            continue
        end
        function_data = json_make_cone_function(data.AT, x_indices, data.b, row_start, cone)
        MOI.add_constraint(backend, function_data, json_cone_set(cone))
        row_start += cone.rowdim
    end

    row_start == length(data.b) + 1 ||
        error("Cone row accounting failed for JSON problem $(test_name).")

    return nothing
end
