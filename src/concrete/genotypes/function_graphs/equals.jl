export depth_first_search!, get_label_sequence

import Base: ==, hash

function depth_first_search!(
    genotype::FunctionGraphGenotype, 
    node_id::Int, 
    visited::Dict{Int, Bool}, 
    label_sequence::Vector{String}
)
    func_string = string(genotype.nodes[node_id].func, "_")
    push!(label_sequence, func_string)
    visited[node_id] = true
    for connection in genotype.nodes[node_id].edges
        if !visited[connection.target]
            node_id = connection.target
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

# TODO: Refactor this to use the `==` and `hash` functions for FunctionGraphGenotype
function ==(a::Edge, b::Edge)
    return a.target == b.target && 
           isapprox(a.weight, b.weight) && 
           a.is_recurrent == b.is_recurrent
end

function hash(a::Edge, h::UInt)
    return hash(a.target, hash(a.weight, hash(a.is_recurrent, h)))
end


function ==(a::Node, b::Node)
    return a.id == b.id && 
           a.func == b.func && 
           a.edges == b.edges  # Note: relies on `==` for Edge
end

function hash(a::Node, h::UInt)
    return hash(a.id, hash(a.func, hash(a.edges, h)))  # Note: relies on `hash` for Edge
end