using CoEvo.Genotypes.FunctionGraphs
using CoEvo.Mutators.FunctionGraphs

# Function to identify all nodes in a subtree rooted at a given node
function identify_subtree_nodes(
    genotype::FunctionGraphGenotype, 
    root_node_id::Int, 
    exclude_input_and_bias_nodes::Bool=true
)
    subtree_node_ids = Set{Int}()
    nodes_to_visit = [root_node_id]

    while !isempty(nodes_to_visit)
        current_node_id = pop!(nodes_to_visit)
        if exclude_input_and_bias_nodes && current_node_id ∈ [genotype.input_node_ids ; genotype.bias_node_ids]
            continue
        end
        push!(subtree_node_ids, current_node_id)

        for connection in genotype.nodes[current_node_id].input_connections
            if connection.input_node_id ∉ subtree_node_ids
                push!(nodes_to_visit, connection.input_node_id)
            end
        end
    end

    return subtree_node_ids
end

# Function to remove a subtree and redirect connections
function remove_subtree_and_redirect(
    genotype::FunctionGraphGenotype, 
    root_node_id::Int, 
    bias_node_id::Int, 
    new_weight::Float64,
    already_visited::Vector{Int} = Int[]
)
    genotype = deepcopy(genotype)
    subtree_node_ids = identify_subtree_nodes(genotype, root_node_id)

    # Redirect connections
    for (id, node) in genotype.nodes
        if id == root_node_id
            continue
        end

        new_input_connections = FunctionGraphConnection[]
        for connection in node.input_connections
            if connection.input_node_id in subtree_node_ids
                push!(new_input_connections, FunctionGraphConnection(
                    input_node_id = bias_node_id, 
                    weight = new_weight, 
                    is_recurrent = false
                ))
            else
                push!(new_input_connections, connection)
            end
        end
        genotype.nodes[id] = FunctionGraphNode(id, node.func, new_input_connections)
    end

    # Remove the nodes in the subtree
    for node_id in setdiff(subtree_node_ids, already_visited)
        delete!(genotype.nodes, node_id)
        filter!(x -> x != node_id, genotype.hidden_node_ids)
    end

    return genotype
end

# Function to remove a subtree and redirect connections
function remove_node_and_redirect(
    genotype::FunctionGraphGenotype, 
    to_prune_node_id::Int, 
    bias_node_id::Int, 
    new_weight::Float64,
)
    genotype = deepcopy(genotype)
    # Redirect connections
    for (id, node) in genotype.nodes
        if id == to_prune_node_id
            continue
        end

        new_input_connections = FunctionGraphConnection[]
        for connection in node.input_connections
            if connection.input_node_id == to_prune_node_id
                push!(new_input_connections, FunctionGraphConnection(
                    input_node_id = bias_node_id, 
                    weight = new_weight, 
                    is_recurrent = false
                ))
            else
                push!(new_input_connections, connection)
            end
        end
        genotype.nodes[id] = FunctionGraphNode(id, node.func, new_input_connections)
    end

    # Remove the nodes in the subtree
    delete!(genotype.nodes, to_prune_node_id)
    filter!(x -> x != to_prune_node_id, genotype.hidden_node_ids)

    return genotype
end




