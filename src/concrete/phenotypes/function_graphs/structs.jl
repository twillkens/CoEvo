using ....Abstract
using ...Genotypes.FunctionGraphs: GraphFunction

struct FunctionGraphPhenotypeCreator <: PhenotypeCreator end

Base.@kwdef struct Edge
    target_index::Int
    is_recurrent::Bool
    weight::Float32
end

@kwdef struct Node{G <: GraphFunction, E <: Edge}
    id::Int
    func::G
    bias::Float32
    edges::Vector{E}
    edge_values::Vector{Float32}
end

@kwdef mutable struct FunctionGraphPhenotype{N <: Node} <: Phenotype
    id::Int
    nodes::Vector{N}
    n_input_nodes::Int
    n_bias_nodes::Int
    n_hidden_nodes::Int
    n_output_nodes::Int
    previous_node_states::Vector{Float32}
    current_node_states::Vector{Float32}
    output_values::Vector{Float32}
end



