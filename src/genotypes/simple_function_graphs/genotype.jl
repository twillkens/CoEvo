export SimpleFunctionGraphGenotype, SimpleFunctionGraphGenotypeCreator
export SimpleFunctionGraphEdge, SimpleFunctionGraphNode
export create_genotypes

using Base: @kwdef
using ...Counters.Basic

"""
    SimpleFunctionGraphEdge

Represents a connection in a function graph. It defines an input node via its ID, 
a weight for the connection, and a flag indicating if the connection is recurrent.
"""
@kwdef mutable struct SimpleFunctionGraphEdge
    target::Int
    weight::Float64
    is_recurrent::Bool
end

"""
    SimpleFunctionGraphNode

Represents a node in a function graph. Each node has a unique ID, a function (represented 
by a symbol), and a list of input connections (`SimpleFunctionGraphEdge`).
"""
@kwdef mutable struct SimpleFunctionGraphNode
    id::Int
    func::Symbol
    edges::Vector{SimpleFunctionGraphEdge}
end

function SimpleFunctionGraphNode(id::Int, func::Symbol)
    return SimpleFunctionGraphNode(id, func, SimpleFunctionGraphEdge[])
end

@kwdef struct SimpleFunctionGraphGenotype{N <: SimpleFunctionGraphNode} <: Genotype
    nodes::Vector{N}
end

"""
    SimpleFunctionGraphGenotypeCreator

Structure to facilitate the creation of `SimpleFunctionGraphGenotype`. It specifies the 
number of inputs, biases, outputs, and nodes associated with each output.
"""
@kwdef struct SimpleFunctionGraphGenotypeCreator <: GenotypeCreator
    n_inputs::Int
    n_bias::Int
    n_outputs::Int
end

function get_initial_genotype(genotype_creator::SimpleFunctionGraphGenotypeCreator)
    counter = BasicCounter(1)
    input_ids = [-id for id in count!(counter, genotype_creator.n_inputs)]
    bias_ids = [-id for id in count!(counter, genotype_creator.n_bias)]
    output_ids = [-id for id in count!(counter, genotype_creator.n_outputs)]
    input_nodes = [SimpleFunctionGraphNode(id, :INPUT) for id in input_ids]
    bias_nodes = [SimpleFunctionGraphNode(id, :BIAS) for id in bias_ids]
    output_nodes = [
        SimpleFunctionGraphNode(
            id, 
            :OUTPUT,
            [SimpleFunctionGraphEdge(first(input_ids), 0.0, true)]
        ) for id in output_ids
    ]
    nodes = [input_nodes; bias_nodes; output_nodes]
    genotype = SimpleFunctionGraphGenotype(nodes)
    return genotype
end



function create_genotypes(
    genotype_creator::SimpleFunctionGraphGenotypeCreator, 
    ::AbstractRNG,
    ::Counter,
    n_population::Int
)
    genotypes = [get_initial_genotype(genotype_creator) for _ in 1:n_population]
    return genotypes
end
