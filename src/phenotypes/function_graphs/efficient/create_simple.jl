using ....Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphGenotype

function sort_layer(node_ids::Vector{Int}, genotype::SimpleFunctionGraphGenotype)
    # Define a helper function to determine if node B has a nonrecurrent connection to node A
    has_nonrecurrent_connection(A::Int, B::Int) = any(
        edge -> edge.target == B && !edge.is_recurrent, 
        genotype[A].edges
    )

    # Sort the node_ids based on the helper function
    sort!(node_ids, by = A -> sum(has_nonrecurrent_connection(A, B) for B in node_ids))

    return node_ids
end

function construct_layers(genotype::SimpleFunctionGraphGenotype)
    layers = Vector{Vector{Int}}()
    # Initialize pool with all nodes except the input and output nodes
    node_pool = Set(genotype.node_ids)
    first_layer = [genotype.input_ids ; genotype.bias_ids]
    last_layer = genotype.output_ids
    setdiff!(node_pool, [first_layer; last_layer])

    current_layer = first_layer
    while !isempty(current_layer)
        # Add the current layer to layers
        push!(layers, current_layer)
        # Flatten all previous layers for easy membership checking
        flattened_previous_layers = vcat(layers...)
        # Find the nodes that use the current layer as inputs and meet all dependencies
        next_layer = Int[]
        for node_id in node_pool
            node = genotype[node_id]
            targets = [
                edge.target 
                for edge in node.edges
                if !edge.is_recurrent
            ]
            if all(target -> target in flattened_previous_layers, targets)
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
    push!(layers, last_layer)

    return layers
end


function make_linearized_nodes(
    genotype::SimpleFunctionGraphGenotype, 
    ordered_node_ids::Vector{Int}, 
)
    node_id_to_position_dict = Dict(id => idx for (idx, id) in enumerate(ordered_node_ids))
    # Step 1: Create all nodes first with empty connections
    linearized_nodes = Vector{EfficientFunctionGraphNode}(undef, length(ordered_node_ids))

    for (i, id) in enumerate(ordered_node_ids)
        # Find the genotype node by its ID
        genotype_node = genotype[id]
        func = FUNCTION_MAP[genotype_node.func]
        input_connections = EfficientFunctionGraphConnection[]
        for edge in genotype_node.edges
            target_node_index = node_id_to_position_dict[edge.target]
            new_connection = EfficientFunctionGraphConnection(
                input_node_index = target_node_index,
                weight = Float32(edge.weight)
            )
            push!(input_connections, new_connection)
        end

        linearized_nodes[i] = EfficientFunctionGraphNode(
            id = id,
            func = func,
            input_connections = input_connections,
            input_values = zeros(Float32, func.arity)
        )
    end

    return linearized_nodes
end

function create_phenotype(
    ::EfficientFunctionGraphPhenotypeCreator, genotype::SimpleFunctionGraphGenotype, id::Int
)
    genotype = minimize(genotype)
    layers = construct_layers(genotype)
    ordered_node_ids = vcat(layers...)
    linearized_nodes = make_linearized_nodes(genotype, ordered_node_ids)

    node_states = zeros(Float32, length(linearized_nodes))
    for i in eachindex(linearized_nodes)
        if linearized_nodes[i].func.name == :BIAS
            node_states[i] = 1.0
        end
    end

    output_values = zeros(Float32, length(genotype.output_ids))

    phenotype = EfficientFunctionGraphPhenotype(
        id = id,
        nodes = linearized_nodes,
        n_input_nodes = length(genotype.input_ids),
        n_bias_nodes = length(genotype.bias_ids),
        n_hidden_nodes = length(genotype.hidden_ids),
        n_output_nodes = length(genotype.output_ids),
        node_states = node_states,
        #node_states = MVector(zeros(Float32, length(linearized_nodes))...),
        output_values = output_values
    )
    return phenotype
end


