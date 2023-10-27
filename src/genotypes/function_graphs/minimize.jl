export get_size, minimize

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