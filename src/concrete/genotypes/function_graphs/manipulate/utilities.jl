export get_random_nonrecurrent_edge_target, get_random_recurrent_edge_target
export get_random_uniform_value, get_random_bias_value, get_random_weight_value
export get_invalid_nonrecurrent_targets, get_valid_nonrecurrent_edge_targets
export relabel_node_ids!

using ....Abstract

function get_invalid_nonrecurrent_targets(
    genotype::FunctionGraphGenotype, node::Node
)
    target_node_id = node.id
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

function get_valid_nonrecurrent_edge_targets(genotype::FunctionGraphGenotype, node::Node)
    all_targets = [genotype.input_ids ; genotype.bias_ids ; genotype.hidden_ids]
    invalid_targets = get_invalid_nonrecurrent_targets(genotype, node)
    valid_targets = setdiff(all_targets, invalid_targets)
    return valid_targets
end

get_valid_nonrecurrent_edge_targets(genotype::FunctionGraphGenotype, id::Int) = 
    get_valid_nonrecurrent_edge_targets(genotype, first(filter(node -> node.id == id, genotype.nodes)))


function get_random_nonrecurrent_edge_target(
    genotype::FunctionGraphGenotype, node::Node, state::State
)
    valid_targets = get_valid_nonrecurrent_edge_targets(genotype, node)
    target = rand(state.rng, valid_targets)
    return target
end

get_random_recurrent_edge_target(genotype::FunctionGraphGenotype, state::State) = 
    rand(state.rng, [genotype.input_ids ; genotype.bias_ids ; genotype.hidden_ids])

get_random_uniform_value(values::Tuple{Float32, Float32}, state::State) = 
    rand(state.rng, Uniform(values...))

function relabel_node_ids!(genotype::FunctionGraphGenotype, counter::Counter)
    # Create a map to track old to new ID mappings
    id_map = Dict{Int, Int}()

    # Update node IDs
    for node in genotype.hidden_nodes
        new_id = count!(counter)
        id_map[node.id] = new_id
        node.id = new_id
    end
    for edge in genotype.edges
        if haskey(id_map, edge.source)
            edge.source = id_map[edge.source]
        end
        if haskey(id_map, edge.target)
            edge.target = id_map[edge.target]
        end
    end

end