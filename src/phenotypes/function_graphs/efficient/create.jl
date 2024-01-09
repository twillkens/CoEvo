using ....Genotypes.FunctionGraphs: FunctionGraphGenotype
using ....Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphGenotype

function create_node_id_to_position_dict(ordered_node_ids::Vector{Int})
    return Dict(id => idx for (idx, id) in enumerate(ordered_node_ids))
end

function make_linearized_nodes(
    genotype::FunctionGraphGenotype, 
    ordered_node_ids::Vector{Int}, 
    node_id_to_position_dict::Dict{Int, Int}
)
    # Step 1: Create all nodes first with empty connections
    linearized_nodes = Vector{EfficientFunctionGraphNode}(undef, length(ordered_node_ids))

    for (i, id) in enumerate(ordered_node_ids)
        node = genotype.nodes[id]
        func = FUNCTION_MAP[node.func]

        linearized_nodes[i] = EfficientFunctionGraphNode(
            id = id,
            func = func,
            input_connections = EfficientFunctionGraphConnection[],
            input_values = zeros(Float32, func.arity)
        )
    end

    # Step 2: Update each node's connections
    for node in linearized_nodes
        genotype_node = genotype.nodes[node.id]
        for connection in genotype_node.input_connections
            input_node_index = node_id_to_position_dict[connection.input_node_id]
            new_connection = EfficientFunctionGraphConnection(
                input_node_index = input_node_index,
                weight = Float32(connection.weight),
            )
            push!(node.input_connections, new_connection)
        end
    end

    return linearized_nodes
end

function create_phenotype(
    ::EfficientFunctionGraphPhenotypeCreator, genotype::FunctionGraphGenotype, id::Int
)::EfficientFunctionGraphPhenotype
    genotype = minimize(genotype)
    layers = construct_layers(genotype)
    ordered_node_ids = vcat(layers...)
    node_id_to_position_dict = create_node_id_to_position_dict(ordered_node_ids)
    linearized_nodes = make_linearized_nodes(genotype, ordered_node_ids, node_id_to_position_dict)

    node_states = zeros(Float32, length(linearized_nodes))
    for i in eachindex(linearized_nodes)
        if linearized_nodes[i].func.name == :BIAS
            node_states[i] = 1.0
        end
    end

    output_values = zeros(Float32, length(genotype.output_node_ids))

    phenotype = EfficientFunctionGraphPhenotype(
        id = id,
        nodes = linearized_nodes,
        n_input_nodes = length(genotype.input_node_ids),
        n_bias_nodes = length(genotype.bias_node_ids),
        n_hidden_nodes = length(genotype.hidden_node_ids),
        n_output_nodes = length(genotype.output_node_ids),
        node_states = node_states,
        #node_states = MVector(zeros(Float32, length(linearized_nodes))...),
        output_values = output_values
    )
    return phenotype
end


