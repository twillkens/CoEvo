
struct EfficientFunctionGraphPhenotypeCreator <: PhenotypeCreator end

abstract type Connection end
abstract type Node end

struct NullNode <: Node end

struct NullConnection <: Connection end


Base.@kwdef struct EfficientFunctionGraphConnection <: Connection
    input_node_index::Int
    weight::Float32
end

@kwdef struct EfficientFunctionGraphNode{G <: GraphFunction, C <: Connection} <: Node
    id::Int
    func::G
    input_connections::Vector{C}
    input_values::Vector{Float32}
end

@kwdef struct EfficientFunctionGraphPhenotype{N <: Node} <: Phenotype
    id::Int
    nodes::Vector{N}
    n_input_nodes::Int
    n_bias_nodes::Int
    n_hidden_nodes::Int
    n_output_nodes::Int
    node_states::Vector{Float32}
    output_values::Vector{Float32}
end



