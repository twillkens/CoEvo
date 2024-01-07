
function act!(phenotype::EfficientFunctionGraphPhenotype, input_values::Vector{Float32})
    @inbounds begin
        phenotype.output_values[1] = phenotype.node_states[end]
        phenotype.node_states[1] = input_values[1]
        phenotype.node_states[2] = input_values[2]

        for i in 4:length(phenotype.nodes)
            node = phenotype.nodes[i]
            for j in eachindex(node.input_connections)
                input_connection = node.input_connections[j]
                input_node_value = phenotype.node_states[input_connection.input_node_index]
                node.input_values[j] = input_connection.weight * input_node_value
            end
            phenotype.node_states[i] = evaluate_function(node.func, node.input_values)
        end
    end
    return phenotype.output_values
end

function act!(phenotype::EfficientFunctionGraphPhenotype, input_values::Vector{Float64})
    output_values = act!(phenotype, Float32.(input_values))
    return output_values
end

function reset!(phenotype::EfficientFunctionGraphPhenotype)
    for i in eachindex(phenotype.node_states)
        phenotype.node_states[i] = 0.0f0
    end
    for i in eachindex(phenotype.output_values)
        phenotype.output_values[i] = 0.0f0
    end
end