using ....Genotypes.SimpleFunctionGraphs: SimpleFunctionGraphGenotype, sort_by_execution_order!
using ....Genotypes: minimize



function make_linearized_nodes(
    genotype::SimpleFunctionGraphGenotype, ordered_node_ids::Vector{Int}, 
)
    node_id_to_position_dict = Dict(id => idx for (idx, id) in enumerate(ordered_node_ids))
    # Step 1: Create all nodes first with empty connections
    linearized_nodes = Vector{Node}(undef, length(ordered_node_ids))

    for (i, id) in enumerate(ordered_node_ids)
        # Find the genotype node by its ID
        genotype_node = genotype[id]
        func = FUNCTION_MAP[genotype_node.func]
        edges = Edge[]
        for edge in genotype_node.edges
            target_node_index = node_id_to_position_dict[edge.target]
            phenotype_edge = Edge(
                target_index = target_node_index,
                is_recurrent = edge.is_recurrent,
                weight = Float32(edge.weight)
            )
            push!(edges, phenotype_edge)
        end

        linearized_nodes[i] = Node(
            id = id,
            func = func,
            edges = edges,
            edge_values = zeros(Float32, func.arity)
        )
    end

    return linearized_nodes
end

function create_phenotype(
    ::CompleteFunctionGraphPhenotypeCreator, genotype::SimpleFunctionGraphGenotype, id::Int
)
    genotype = minimize(genotype)
    sort_by_execution_order!(genotype)
    ordered_node_ids = [node.id for node in genotype.nodes]
    linearized_nodes = make_linearized_nodes(genotype, ordered_node_ids)

    previous_node_states = zeros(Float32, length(linearized_nodes))
    current_node_states = zeros(Float32, length(linearized_nodes))
    for i in eachindex(linearized_nodes)
        if linearized_nodes[i].func.name == :BIAS
            previous_node_states[i] = 1.0
            current_node_states[i] = 1.0
        end
    end

    output_values = zeros(Float32, length(genotype.output_ids))

    phenotype = CompleteFunctionGraphPhenotype(
        id = id,
        nodes = linearized_nodes,
        n_input_nodes = length(genotype.input_ids),
        n_bias_nodes = length(genotype.bias_ids),
        n_hidden_nodes = length(genotype.hidden_ids),
        n_output_nodes = length(genotype.output_ids),
        previous_node_states = previous_node_states,
        current_node_states = current_node_states,
        output_values = output_values
    )
    return phenotype
end


