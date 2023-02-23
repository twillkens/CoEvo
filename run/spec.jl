function laplacian_matrix(
    g::GNNGraph, T::DataType = eltype(g); dir::Symbol = :out, add_self_loops=false
)
    A = adjacency_matrix(g, T; dir = dir)
    A = add_self_loops ? A + I : A
    D = Diagonal(vec(sum(A; dims = 2)))
    return (D - A) * 2
end

function graphspectrum(g::GNNGraph; add_self_loops = false, dir = :both, usenorm::Bool = true)
    lp = usenorm ?
        normalized_laplacian(g, add_self_loops = add_self_loops, dir = dir) :
        laplacian_matrix(g, add_self_loops = add_self_loops, dir = dir)
    spec = eigvals(collect(lp))
    return spec
end

function padspec(spec1::Vector{<:Real}, spec2::Vector{<:Real})
    diff = length(spec1) - length(spec2)
    diff < 0 ? ([spec1; zeros(abs(diff))], spec2) : (spec1, [spec2; zeros(diff)])
end

function clipspec(spec1::Vector{Float64}, spec2::Vector{Float64})
    k = min(length(spec1), length(spec2))
    spec1[1:k], spec2[1:k]
end

function graph_distance(
    g1::GNNGraph, g2::GNNGraph; kwargs...
)
    spec1, spec2 = padspec(graphspectrum(g1; kwargs...), graphspectrum(g2; kwargs...))
    norm(spec1 - spec2)
end
