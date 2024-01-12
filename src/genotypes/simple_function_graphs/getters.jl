
Base.getproperty(genotype::SimpleFunctionGraphGenotype, prop::Symbol) = begin
    if prop == :input_nodes
        return filter(node -> node.func == :INPUT, genotype.nodes)
    elseif prop == :bias_nodes
        return filter(node -> node.func == :BIAS, genotype.nodes)
    elseif prop == :hidden_nodes
        return filter(node -> node.func ∉ [:INPUT, :BIAS, :OUTPUT], genotype.nodes)
    elseif prop == :output_nodes
        return filter(node -> node.func == :OUTPUT, genotype.nodes)
    elseif prop == :input_ids
        return [node.id for node in filter(node -> node.func == :INPUT, genotype.nodes)]
    elseif prop == :bias_ids
        return [node.id for node in filter(node -> node.func == :BIAS, genotype.nodes)]
    elseif prop == :hidden_ids
        return [node.id for node in filter(node -> node.func ∉ [:INPUT, :BIAS, :OUTPUT], genotype.nodes)]
    elseif prop == :output_ids
        return [node.id for node in filter(node -> node.func == :OUTPUT, genotype.nodes)]
    elseif prop == :node_ids
        return [node.id for node in genotype.nodes]
    elseif prop == :edges
        return [edge for node in genotype.nodes for edge in node.edges]
    else
        # Fallback to default behavior for other properties
        return getfield(genotype, prop)
    end
end

Base.getindex(genotype::SimpleFunctionGraphGenotype, id::Int) = begin
    return first(filter(node -> node.id == id, genotype.nodes))
end
