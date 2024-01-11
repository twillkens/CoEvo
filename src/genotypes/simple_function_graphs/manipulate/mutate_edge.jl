export mutate_edge!, create_edge, get_valid_nonrecurrent_edge_targets
export get_valid_recurrent_edge_targets, get_invalid_nonrecurrent_targets

using ...Abstract 
using ...Abstract.States

function get_invalid_nonrecurrent_targets(
    genotype::SimpleFunctionGraphGenotype, target_node_id::Int
)
    visited = Set{Int}()
    invalid_candidates = Set{Int}([genotype.output_ids ; target_node_id])

    function reverse_dfs(node_id::Int)
        if node_id in visited
            return
        end
        push!(visited, node_id)
        push!(invalid_candidates, node_id)
        for node in genotype.nodes
            for edge in node.edges
                # Check if the edge is non-recurrent and leads to the current node
                if !edge.is_recurrent && edge.target == node_id
                    reverse_dfs(node.id)
                end
            end
        end
    end

    reverse_dfs(target_node_id)
    return collect(invalid_candidates)
end

get_valid_recurrent_edge_targets(genotype::SimpleFunctionGraphGenotype) = [
    genotype.input_ids ; genotype.bias_ids ; genotype.hidden_ids
]

function get_valid_nonrecurrent_edge_targets(genotype::SimpleFunctionGraphGenotype, node_id::Int)
    targets = get_valid_recurrent_edge_targets(genotype)
    #println("targets = ", targets)
    invalid_targets = get_invalid_nonrecurrent_targets(genotype, node_id)
    #println("invalid_targets = ", invalid_targets)
    setdiff!(targets, invalid_targets)
    return targets
end

function create_edge(
    genotype::SimpleFunctionGraphGenotype, 
    node::SimpleFunctionGraphNode,
    mutator::Mutator, 
    state::State
)
    is_recurrent = rand(state.rng) < mutator.recurrent_edge_probability ? true : false
    targets = is_recurrent ? 
        get_valid_recurrent_edge_targets(genotype) : 
        get_valid_nonrecurrent_edge_targets(genotype, node.id)
    target = rand(state.rng, targets)
    edge = SimpleFunctionGraphEdge(target, 0.0, is_recurrent)
    if target == node.id && !is_recurrent
        println("genotype = ", genotype)
        println("edge = ", edge)
        throw(ErrorException("Edge to self is non-recurrent"))
    end
    return edge
end

function mutate_edge!(genotype::SimpleFunctionGraphGenotype, mutator::Mutator, state::State)
    valid_nodes = [genotype.hidden_nodes ; genotype.output_nodes]
    if length(valid_nodes) == 0
        return
    end
    node = rand(state.rng, valid_nodes)
    edge_index = rand(state.rng, 1:length(node.edges))
    new_edge = create_edge(genotype, node, mutator, state)
    node.edges[edge_index] = new_edge
end
