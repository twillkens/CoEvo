export get_size, minimize, remove_node_and_redirect, get_prunable_genes
export substitute_node_with_bias_connection

import ..Genotypes: get_prunable_genes

"""
    get_size(genotype::FunctionGraphGenotype) -> Int

Get the size of a `FunctionGraphGenotype` as determined by the number of hidden nodes it contains.

# Arguments:
- `genotype::FunctionGraphGenotype`: The genotype whose size we wish to determine.

# Returns:
- An integer representing the number of hidden nodes in the genotype.
"""
function get_size(genotype::FunctionGraphGenotype)
    return length(genotype.hidden_node_ids)
end


"""
    minimize(genotype::FunctionGraphGenotype) -> FunctionGraphGenotype

Minimize a `FunctionGraphGenotype` by removing non-essential nodes. Non-essential nodes are 
those that don't influence the output, as determined by a recursive search starting from 
the output nodes and following input connections.

# Arguments:
- `genotype::FunctionGraphGenotype`: The genotype to minimize.

# Returns:
- A new minimized `FunctionGraphGenotype` that retains only the essential nodes.

# Note:
The returned genotype retains all input, bias, and output nodes as these are always considered essential.
"""
function minimize(genotype::FunctionGraphGenotype)
    # A Set to store IDs of essential nodes.
    essential_nodes_ids = Set{Int}()
    
    # A function to recursively find essential nodes by traversing input connections.
    function find_essential_nodes(node_id::Int)
        # Avoid repeated work if the node is already identified as essential.
        if node_id in essential_nodes_ids
            return
        end
        
        # Add the current node to essential nodes.
        push!(essential_nodes_ids, node_id)
        
        # Recursively call for all input connections of the current node.
        for conn in genotype.nodes[node_id].input_connections
            find_essential_nodes(conn.input_node_id)
        end
    end
    
    # Initialize the search from each output node.
    for output_node_id in genotype.output_node_ids
        find_essential_nodes(output_node_id)
    end
    
    # Ensuring input, bias, and output nodes are always essential.
    union!(essential_nodes_ids, genotype.input_node_ids, genotype.bias_node_ids, genotype.output_node_ids)

    # Construct the minimized genotype, keeping only essential nodes.
    minimized_nodes = Dict(id => node for (id, node) in genotype.nodes if id in essential_nodes_ids)

    # Return a new FunctionGraphGenotype with minimized nodes and unaltered input, bias, and output nodes.
    minimized_genotype = FunctionGraphGenotype(
        input_node_ids = genotype.input_node_ids, 
        bias_node_ids = genotype.bias_node_ids, 
        hidden_node_ids = filter(id -> id in essential_nodes_ids, genotype.hidden_node_ids), 
        output_node_ids = genotype.output_node_ids, 
        nodes = minimized_nodes,
        n_nodes_per_output = genotype.n_nodes_per_output
    )
    return minimized_genotype
end

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
# Prune a single node and return the updated genotype, error, and observation
function substitute_node_with_bias_connection(
    genotype::FunctionGraphGenotype, node_id::Int, weight::Real
)
    bias_node_id = first(genotype.bias_node_ids)
    pruned_genotype = remove_node_and_redirect(genotype, node_id, bias_node_id, Float64(weight))
    pruned_genotype = minimize(pruned_genotype)
    return pruned_genotype
end

function get_prunable_genes(genotype::FunctionGraphGenotype)
    gene_ids = sort(genotype.hidden_node_ids, rev = true)
    return gene_ids
end