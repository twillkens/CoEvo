
struct EfficientFunctionGraphPhenotypeState{P <: Phenotype} <: PhenotypeState
    phenotype::P
    node_values::Dict{Int, Float32}
end

function get_node_value(state::EfficientFunctionGraphPhenotypeState, node_id::Int)
    return state.node_values[node_id]
end

function get_phenotype_state(phenotype::EfficientFunctionGraphPhenotype)
    state = Dict(
        node.id => node.current_value
        for node in phenotype.nodes
    )
    state = EfficientFunctionGraphPhenotypeState(phenotype, state)
    return state
end

#function safe_median(values::Vector{T}) where {T <: Real}
#    median_value = median(values)
#    median_value = isinf(median_value) ? T(0.0) : median_value
#    return median_value
#end

function safe_median(values::Vector{T}) where {T <: Real}
    median_value = median(values)

    # Handle +Inf by returning the maximum non-infinite value for the type T
    if isinf(median_value) && median_value > 0
        return prevfloat(Inf32)
    end

    # Handle -Inf by returning the minimum (negative) non-infinite value for the type T
    if isinf(median_value) && median_value < 0
        return nextfloat(-Inf32)
    end

    # Handle NaN by returning 0
    if isnan(median_value)
        return T(0.0)
    end

    return median_value
end
# TODO: fix to use linearized state
function get_node_median_value(
    #states::Vector{EfficientFunctionGraphPhenotypeState}, node_id::Int
    states::Vector{<:PhenotypeState}, node_id::Int
)
    gene_values = [get_node_value(state, node_id) for state in states]
    gene_median_value = safe_median(gene_values)
    return gene_median_value
end