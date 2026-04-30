using JuMP, MathOptInterface, SparseArrays, LinearAlgebra

struct JsonConeSpec
    kind::Symbol
    dim::Int
    rowdim::Int
end

struct JsonProblemData{T}
    P::SparseMatrixCSC{T,Int}
    q::Vector{T}
    A::SparseMatrixCSC{T,Int}
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

function json_parse_sparse_matrix(data, ::Type{T}) where {T}
    return SparseMatrixCSC(
        Int(data["m"]),
        Int(data["n"]),
        convert(Vector{Int}, data["colptr"]) .+ 1,
        convert(Vector{Int}, data["rowval"]) .+ 1,
        convert(Vector{T}, data["nzval"]),
    )
end

json_parse_vector(data, ::Type{T}) where {T} = convert(Vector{T}, data)

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

    return JsonProblemData{T}(P, q, A, b, cones)
end

function json_add_cone_constraint(model, x, A, b, rows::UnitRange{Int}, cone::JsonConeSpec)
    if cone.kind == :ZeroConeT
        @constraint(model, b[rows] - A[rows, :] * x in MOI.Zeros(cone.dim))
    elseif cone.kind == :NonnegativeConeT
        @constraint(model, b[rows] - A[rows, :] * x in MOI.Nonnegatives(cone.dim))
    elseif cone.kind == :SecondOrderConeT
        @constraint(model, b[rows] - A[rows, :] * x in MOI.SecondOrderCone(cone.dim))
    elseif cone.kind == :PSDTriangleConeT
        @constraint(
            model,
            b[rows] - A[rows, :] * x in MOI.Scaled(MOI.PositiveSemidefiniteConeTriangle(cone.dim)),
        )
    else
        error("Internal error: unsupported cone $(cone.kind).")
    end
    return nothing
end

function json_load(model::GenericModel{T}, test_name) where {T}
    data = json_load_data(test_name, T)

    @variable(model, x[1:length(data.q)])
    @objective(model, Min, dot(data.q, x) + T(1 / 2) * x' * Symmetric(data.P, :U) * x)

    row_start = 1
    for cone in data.cones
        if cone.rowdim == 0
            continue
        end
        rows = row_start:(row_start + cone.rowdim - 1)
        json_add_cone_constraint(model, x, data.A, data.b, rows, cone)
        row_start += cone.rowdim
    end

    row_start == length(data.b) + 1 ||
        error("Cone row accounting failed for JSON problem $(test_name).")

    return nothing
end
