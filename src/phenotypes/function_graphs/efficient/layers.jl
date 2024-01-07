
function sort_layer(node_ids::Vector{Int}, genotype::FunctionGraphGenotype)::Vector{Int}
    # Define a helper function to determine if node B has a nonrecurrent connection to node A
    has_nonrecurrent_connection(A::Int, B::Int) = any(
        conn -> conn.input_node_id == B && !conn.is_recurrent, 
        genotype.nodes[A].input_connections
    )

    # Sort the node_ids based on the helper function
    sort!(node_ids, by = A -> sum(has_nonrecurrent_connection(A, B) for B in node_ids))

    return node_ids
end

function construct_layers(genotype::FunctionGraphGenotype)::Vector{Vector{Int}}
    layers = Vector{Vector{Int}}()
    # Initialize pool with all nodes except the input nodes
    first_layer = [genotype.input_node_ids ; genotype.bias_node_ids]
    node_pool = Set(keys(genotype.nodes))
    setdiff!(node_pool, first_layer)
    current_layer = first_layer
    while !isempty(current_layer)
        # Add the current layer to layers
        push!(layers, current_layer)
        # Flatten all previous layers for easy membership checking
        flattened_previous_layers = vcat(layers...)
        # Find the nodes that use the current layer as inputs and meet all dependencies
        next_layer = Int[]
        for node_id in node_pool
            node = genotype.nodes[node_id]
            # Check if all input nodes of the current node are in the flattened previous layers
            input_node_ids = [
                input_connection.input_node_id 
                for input_connection in node.input_connections
                if !input_connection.is_recurrent
            ]
            # This node is valid if all of its input nodes are in the flattened previous layers
            # or if it has no nonrecurrent input nodes.
            # (This evaluates to `true` if the input_node_ids is empty)
            if all(in_id -> in_id in flattened_previous_layers, input_node_ids)
                push!(next_layer, node_id)
            end
        end
        # Remove the nodes in the next_layer from the pool
        setdiff!(node_pool, next_layer)
        # Sort the next layer
        next_layer = sort_layer(next_layer, genotype)
        # Set the next layer as the current layer for the next iteration
        current_layer = next_layer
    end

    return layers
end