
function act!(phenotype::EfficientFunctionGraphPhenotype, input_values::Vector{Float32})
    @inbounds begin
        n_nodes = length(phenotype.nodes)
        # Update output values from the node_states
        for i in 1:phenotype.n_output_nodes
            output_node_index = n_nodes - phenotype.n_output_nodes + i
            phenotype.output_values[i] = phenotype.node_states[output_node_index]
        end

        # Update node states for input nodes
        for i in 1:phenotype.n_input_nodes
            phenotype.node_states[i] = input_values[i]
        end

        # Starting index for processing nodes beyond input and bias nodes
        start_index = phenotype.n_input_nodes + phenotype.n_bias_nodes + 1

        # Process each node (excluding input and bias nodes)
        for i in start_index:n_nodes
            node = phenotype.nodes[i]
            for j in eachindex(node.input_connections)
                connection = node.input_connections[j]
                input_node_value = phenotype.node_states[connection.input_node_index]
                node.input_values[j] = connection.weight * input_node_value
            end
            phenotype.node_states[i] = evaluate_function(node.func, node.input_values)
        end
    end

    return phenotype.output_values
end

#function act!(phenotype::EfficientFunctionGraphPhenotype, input_values::Vector{Float32})
#    @inbounds begin
#        phenotype.output_values[1] = phenotype.node_states[end]
#        phenotype.node_states[1] = input_values[1]
#        phenotype.node_states[2] = input_values[2]
#
#        for i in 4:length(phenotype.nodes)
#            node = phenotype.nodes[i]
#            for j in eachindex(node.input_connections)
#                input_connection = node.input_connections[j]
#                input_node_value = phenotype.node_states[input_connection.input_node_index]
#                node.input_values[j] = input_connection.weight * input_node_value
#            end
#            phenotype.node_states[i] = evaluate_function(node.func, node.input_values)
#        end
#    end
#    return phenotype.output_values
#end

function act!(phenotype::EfficientFunctionGraphPhenotype, input_values::Vector{T}) where T
    output_values = act!(phenotype, Float32.(input_values))
    output_values = T.(output_values)
    return output_values
end

function reset!(phenotype::EfficientFunctionGraphPhenotype)
    for i in eachindex(phenotype.node_states)
        if phenotype.nodes[i].func.name == :BIAS
            phenotype.node_states[i] = 1.0f0
        else
            phenotype.node_states[i] = 0.0f0
        end
    end
    for i in eachindex(phenotype.output_values)
        phenotype.output_values[i] = 0.0f0
    end
end