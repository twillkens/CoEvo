export sort_by_execution_order!

function sort_by_execution_order!(genotype::SimpleFunctionGraphGenotype)
    # Classify nodes
    input_nodes = filter(node -> node.func == :INPUT, genotype.nodes)
    bias_nodes = filter(node -> node.func == :BIAS, genotype.nodes)
    output_nodes = filter(node -> node.func == :OUTPUT, genotype.nodes)
    hidden_nodes = filter(node -> node.func ∉ [:INPUT, :BIAS, :OUTPUT], genotype.nodes)

    # Helper function to check if node B has a nonrecurrent connection to node A
    function has_nonrecurrent_connection(A::Node, B::Node)
        any(edge -> edge.target == B.id && !edge.is_recurrent, A.edges)
    end

    # Sorting function for nodes within the same layer
    function sort_layer(nodes::Vector{Node})
        sort(nodes, by = node -> sum(has_nonrecurrent_connection(node, other) for other in nodes))
    end

    # Constructing layers
    layers = [input_nodes, bias_nodes]
    remaining_nodes = Set(hidden_nodes)
    current_layer = vcat(input_nodes, bias_nodes)

    i = 0

    while !isempty(remaining_nodes)
        next_layer = Node[]
        for node in copy(remaining_nodes)
            if all([edge.is_recurrent || any(prev_node -> prev_node.id == edge.target, current_layer) for edge in node.edges])

                push!(next_layer, node)
                setdiff!(remaining_nodes, [node])
            end
        end
        sorted_next_layer = sort_layer(next_layer)
        push!(layers, sorted_next_layer)
        append!(current_layer, sorted_next_layer)
        i += 1
        if i > 10000
            genotype = string(genotype)
            println("genotype = $genotype")
            throw(ArgumentError("Infinite loop detected"))
        end
    end

    # Add output layer
    push!(layers, output_nodes)

    # Flatten layers and sort each layer by node ID
    sorted_nodes = [node for layer in layers for node in sort(layer, by = x -> x.id)]

    # Update genotype in-place
    for i in 1:length(genotype.nodes)
        genotype.nodes[i] = sorted_nodes[i]
    end

end
