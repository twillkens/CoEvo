export depth_first_search!, get_label_sequence

import Base: ==, hash

function depth_first_search!(
    label_sequence::Vector{String},
    genotype::FunctionGraphGenotype, 
    node_id::Int, 
    visited::Dict{Int, Bool}, 
)
    current_node = find_node(genotype, node_id)
    func_string = string(current_node.func)
    push!(label_sequence, func_string)
    visited[node_id] = true

    for edge in current_node.edges
        # Append edge recurrency information to the label sequence
        edge_info = edge.is_recurrent ? "R" : "N"
        push!(label_sequence, edge_info)

        if !visited[edge.target]
            depth_first_search!(label_sequence, genotype, edge.target, visited)
        end
    end
end

function get_label_sequence(genotype::FunctionGraphGenotype)
    visited = Dict{Int, Bool}([(node.id, false) for node in genotype.nodes])
    label_sequence = String[]

    for output_node in filter(node -> node.is_output, genotype.nodes)
        depth_first_search!(genotype, output_node.id, visited, label_sequence)
    end

    return join(label_sequence, "_")
end


# Helper function to find a node by its ID
function find_node(genotype::FunctionGraphGenotype, node_id::Int)
    return findfirst(node -> node.id == node_id, genotype.nodes)
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