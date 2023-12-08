
function depth_first_search!(
    genotype::FunctionGraphGenotype, 
    node_id::Int, 
    visited::Dict{Int, Bool}, 
    label_sequence::Vector{String}
)
    func_string = string(genotype.nodes[node_id].func, "_")
    push!(label_sequence, func_string)
    visited[node_id] = true
    for connection in genotype.nodes[node_id].input_connections
        if !visited[connection.input_node_id]
            node_id = connection.input_node_id
            depth_first_search!(genotype, node_id, visited, label_sequence)
        end
    end
end

function get_label_sequence(genotype::FunctionGraphGenotype)
    visited = Dict{Int, Bool}([(id, false) for id in keys(genotype.nodes)])
    label_sequence = String[]
    for output_id in genotype.output_node_ids
        depth_first_search!(genotype, output_id, visited, label_sequence)
    end
    label_sequence = join(label_sequence, "_")
    return label_sequence
end

function ==(genotype_1::FunctionGraphGenotype, genotype_2::FunctionGraphGenotype)
    if length(genotype_1.nodes) != length(genotype_2.nodes)
        return false
    end
    label_sequence_1 = get_label_sequence(genotype_1)
    label_sequence_2 = get_label_sequence(genotype_2)
    return label_sequence_1 == label_sequence_2
end

function hash(genotype::FunctionGraphGenotype, h::UInt)
    # Helper function for depth-first search to create a label sequence string
    label_sequence = get_label_sequence(genotype)
    # Combine the hash of the label sequence string with the provided hash seed
    return hash(label_sequence, h)
end
