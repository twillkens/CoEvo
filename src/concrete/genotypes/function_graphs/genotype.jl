export FunctionGraphGenotype, FunctionGraphGenotypeCreator
export Edge, Node
export create_genotypes

using Base: @kwdef
import ....Interfaces: create_genotypes
using ...Counters.Basic: BasicCounter
using ....Abstract

"""
    Edge

Represents a connection in a function graph. It defines an input node via its ID, 
a weight for the connection, and a flag indicating if the connection is recurrent.
"""

Base.@kwdef mutable struct Edge
    source::Int = 1
    target::Int = 1
    weight::Float32 = 1.0f0
    is_recurrent::Bool = false
end

Edge(source::Int, target::Int) = Edge(source = source, target = target)

Edge(source::Int, target::Int, is_recurrent::Bool) = Edge(
    source = source, target = target, is_recurrent = is_recurrent
)

"""
    Node

Represents a node in a function graph. Each node has a unique ID, a function (represented 
by a symbol), and a list of input connections (`Edge`).
"""
Base.@kwdef mutable struct Node
    id::Int = 1
    func::Symbol = :FUNCTION
    bias::Float32 = 1.0
    edges::Vector{Edge} = Edge[]
end

Node(id::Int, func::Symbol) = Node(id = id, func = func)

Node(id::Int, func::Symbol, edges::Vector{Edge}) = Node(id = id, func = func, edges = edges)


@kwdef struct FunctionGraphGenotype{N <: Node} <: Genotype
    nodes::Vector{N}
end

"""
    FunctionGraphGenotypeCreator

Structure to facilitate the creation of `FunctionGraphGenotype`. It specifies the 
number of inputs, biases, outputs, and nodes associated with each output.
"""
@kwdef struct FunctionGraphGenotypeCreator <: GenotypeCreator
    n_inputs::Int
    n_hidden::Int
    n_bias::Int
    n_outputs::Int
end

function get_ids(counter::Counter, n_ids::Int, make_negative::Bool)
    ids = [id for id in step!(counter, n_ids)]
    if make_negative
        ids = [-id for id in ids]
    end
    return ids
end

create_input_nodes(genotype_creator::FunctionGraphGenotypeCreator, counter::Counter) = [
    Node(id = id, func = :INPUT) 
    for id in get_ids(counter, genotype_creator.n_inputs, true)
]

create_bias_nodes(genotype_creator::FunctionGraphGenotypeCreator, counter::Counter) = [
    Node(id = id, func = :BIAS) 
    for id in get_ids(counter, genotype_creator.n_bias, true)
]

create_output_nodes(genotype_creator::FunctionGraphGenotypeCreator, counter::Counter) = [
    Node(
        id = id, 
        func = :OUTPUT,
        edges = [Edge(source = id, target = -1, weight = 1.0f0, is_recurrent = false)]
    ) for id in get_ids(counter, genotype_creator.n_outputs, true)
]

function create_genotype(genotype_creator::FunctionGraphGenotypeCreator)
    counter = BasicCounter(1)
    nodes = [
        create_input_nodes(genotype_creator, counter);
        create_bias_nodes(genotype_creator, counter);
        create_output_nodes(genotype_creator, counter);
    ]
    genotype = FunctionGraphGenotype(nodes)
    return genotype
end

function create_genotypes(genotype_creator::FunctionGraphGenotypeCreator, n_genotypes::Int)
    genotypes = [create_genotype(genotype_creator) for _ in 1:n_genotypes]
    return genotypes
end

create_genotypes(genotype_creator::FunctionGraphGenotypeCreator, n_genotypes::Int, ::State) =
    create_genotypes(genotype_creator, n_genotypes)
