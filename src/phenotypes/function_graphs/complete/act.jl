
function act!(phenotype::CompleteFunctionGraphPhenotype, edge_values::Vector{Float32})
    @inbounds begin
        n_nodes = length(phenotype.nodes)
        # Update output values from the node_states

        # Update node states for input nodes
        for i in 1:phenotype.n_input_nodes
            phenotype.current_node_states[i] = edge_values[i]
        end

        # Starting index for processing nodes beyond input and bias nodes
        start_index = phenotype.n_input_nodes + phenotype.n_bias_nodes + 1

        # Process each node (excluding input and bias nodes)
        for i in start_index:n_nodes
            node = phenotype.nodes[i]
            for j in eachindex(node.edges)
                edge = node.edges[j]
                edge_value = edge.is_recurrent ?
                    phenotype.previous_node_states[edge.target_index] :
                    phenotype.current_node_states[edge.target_index]
                node.edge_values[j] = edge.weight * edge_value
            end
            phenotype.current_node_states[i] = evaluate_function(node.func, node.edge_values)
        end

        for i in 1:phenotype.n_output_nodes
            output_node_index = n_nodes - phenotype.n_output_nodes + i
            phenotype.output_values[i] = phenotype.current_node_states[output_node_index]
        end

        previous_node_states = phenotype.previous_node_states
        current_node_states = phenotype.current_node_states
        phenotype.previous_node_states = current_node_states
        phenotype.current_node_states = previous_node_states
    end

    return phenotype.output_values
end

function act!(phenotype::CompleteFunctionGraphPhenotype, edge_values::Vector{T}) where T
    output_values = act!(phenotype, Float32.(edge_values))
    output_values = T.(output_values)
    return output_values
end

function reset!(phenotype::CompleteFunctionGraphPhenotype)
    for i in eachindex(phenotype.current_node_states)
        if phenotype.nodes[i].func.name == :BIAS
            phenotype.current_node_states[i] = 1.0f0
            phenotype.previous_node_states[i] = 1.0f0
        else
            phenotype.current_node_states[i] = 0.0f0
            phenotype.previous_node_states[i] = 0.0f0
        end
    end
    for i in eachindex(phenotype.output_values)
        phenotype.output_values[i] = 0.0f0
    end
end