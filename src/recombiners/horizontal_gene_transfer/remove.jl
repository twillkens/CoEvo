
@kwdef struct EdgeSubstitution
    node_id::Int
    edge_index::Int
    target::Int
end

function perform_substitution!(
    genotype::SimpleFunctionGraphGenotype, substitution::EdgeSubstitution
)
    node = genotype[substitution.node_id]
    connection = node.edges[substitution.edge_index]
    connection.target = substitution.target
end

# Define equality
function Base.:(==)(
    a::EdgeSubstitution, b::EdgeSubstitution
)
    return a.node_id == b.node_id &&
           a.edge_index == b.edge_index &&
           a.target == b.target
end

# Define hash
function Base.hash(a::EdgeSubstitution, h::UInt)
    return hash(a.node_id, hash(a.edge_index, hash(a.target, h)))
end

function remove_node!(
    genotype::SimpleFunctionGraphGenotype, 
    node_to_delete_id::Int, 
    substitutions::Vector{EdgeSubstitution}
)
    illegal_to_remove = [
        genotype.input_ids ; genotype.bias_ids ; genotype.output_ids
    ]
    if node_to_delete_id in illegal_to_remove
        throw(ErrorException("Cannot remove input, bias, or output node"))
    end
    filter!(node -> node.id != node_to_delete_id, genotype.nodes)
    [perform_substitution!(genotype, substitution) for substitution in substitutions]
end

function get_all_substitutions(
    genotype::SimpleFunctionGraphGenotype, node_to_delete_id::Int, rng::AbstractRNG
)
    nodes = [node for node in genotype.nodes if node.id != node_to_delete_id]
    non_output_ids = [
        genotype.input_ids ; genotype.bias_ids ; genotype.hidden_ids
    ]
    valid_targets = [id for id in non_output_ids if id != node_to_delete_id]

    substitutions = EdgeSubstitution[]
    for node in nodes
        for (index, edge) in enumerate(node.edges)
            if edge.target == node_to_delete_id
                substitution = EdgeSubstitution(
                    node_id = node.id,
                    edge_index = index,
                    target = rand(rng, valid_targets)
                )
                push!(substitutions, substitution)
            end
        end
    end
    
    return substitutions
end

function remove_node!(rng::AbstractRNG, genotype::SimpleFunctionGraphGenotype,)
    if length(genotype.hidden_ids) == 0
        return 
    end
    node_to_delete_id = rand(rng, genotype.hidden_ids)
    substitutions = get_all_substitutions(genotype, node_to_delete_id, rng)
    remove_node!(genotype, node_to_delete_id, substitutions)
end