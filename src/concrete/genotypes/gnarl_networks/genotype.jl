export NodeGene, ConnectionGene
export GnarlNetworkGenotype, GnarlNetworkGenotypeCreator
export RandomFCGnarlNetworkGenotypeCreator, create_genotypes, create_random_fc_genotype

import ....Interfaces: create_genotypes
using ....Abstract
using ....Interfaces
#using ....Interfaces: step!

"""
    NodeGene <: Gene

Represents a node in the GNARL network. Each node has a unique ID 
and a position in the network topology.

# Fields:
- `id`: Unique identifier for the node.
- `position`: Position of the node in the network, often used for visualization or topology-based operations.
"""
Base.@kwdef struct NodeGene <: Gene 
    id::Int
    position::Float32
end

"""
    ConnectionGene <: Gene

Represents a connection between nodes in the GNARL network. 
Each connection has a unique ID, an origin and destination node, 
and a weight determining the strength and direction of the connection.

# Fields:
- `id`: Unique identifier for the connection.
- `origin`: Identifier of the origin node of the connection.
- `destination`: Identifier of the destination node of the connection.
- `weight`: Weight of the connection, influencing the signal passed through it.
"""
Base.@kwdef struct ConnectionGene <: Gene 
    id::Int
    origin::Float32
    destination::Float32
    weight::Float32
end

"""
    GnarlNetworkGenotype <: Genotype

A genotype representation for GNARL (GeNeralized Acquisition of Recurrent Links) networks 
developed by Peter Angeline and Jordan Pollack. The genotype contains details about 
the number of input and output nodes, hidden nodes, and their connections.

# Fields:
- `n_input_nodes`: Number of input nodes in the GNARL network.
- `n_output_nodes`: Number of output nodes in the GNARL network.
- `hidden_nodes`: A vector of `NodeGene` representing hidden nodes in the network.
- `connections`: A vector of `ConnectionGene` representing connections between nodes.
"""
Base.@kwdef mutable struct GnarlNetworkGenotype <: Genotype
    n_input_nodes::Int
    n_output_nodes::Int
    hidden_nodes::Vector{NodeGene}
    connections::Vector{ConnectionGene}
end

"""
    GnarlNetworkGenotypeCreator

A utility for creating genotypes for GNARL networks. 
This structure contains basic configuration parameters 
required to initialize a `GnarlNetworkGenotype`.

# Fields:
- `n_input_nodes`: Number of input nodes for the GNARL network genotype to be created.
- `n_output_nodes`: Number of output nodes for the GNARL network genotype to be created.
"""
Base.@kwdef struct GnarlNetworkGenotypeCreator <: GenotypeCreator
    n_input_nodes::Int
    n_output_nodes::Int
end

function create_genotypes(
    genotype_creator::GnarlNetworkGenotypeCreator,
    n_population::Int
)
    genotypes = [
        GnarlNetworkGenotype(
            genotype_creator.n_input_nodes,
            genotype_creator.n_output_nodes,
            Vector{NodeGene}(),
            Vector{ConnectionGene}()
        ) for i in 1:n_population
    ]

    return genotypes
end

function create_genotypes(genotype_creator::GnarlNetworkGenotypeCreator, n_genotype::Int, ::State)
    genotypes = create_genotypes(genotype_creator, n_genotype)
end

Base.@kwdef struct RandomFCGnarlNetworkGenotypeCreator <: GenotypeCreator
    n_input_nodes::Int
    n_hidden_nodes::Int
    n_output_nodes::Int
end

using ...Counters.Basic
using Random
using ....Interfaces

function create_random_fc_genotype(
    genotype_creator::RandomFCGnarlNetworkGenotypeCreator,
    gene_id_counter::Counter = BasicCounter(1),
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    hidden_nodes = [
        NodeGene(id=i, position=rand(rng, Float32)) for i in 1:genotype_creator.n_hidden_nodes
    ]
    input_and_bias_positions = [float(-i) for i in 0:genotype_creator.n_input_nodes]
    hidden_node_positions = [node.position for node in hidden_nodes]
    output_node_positions = [float(i) for i in 1:genotype_creator.n_output_nodes]
    origin_positions = vcat(input_and_bias_positions, hidden_node_positions)
    destination_positions = vcat(hidden_node_positions, output_node_positions)
    connections = ConnectionGene[]
    for origin_position in origin_positions
        for destination_position in destination_positions
            connection = ConnectionGene(
                id = step!(gene_id_counter),
                origin = origin_position,
                destination = destination_position,
                weight = (rand(rng) - 0.5) * 5
            )
            push!(connections, connection)
        end
    end
    genotype = GnarlNetworkGenotype(
        genotype_creator.n_input_nodes,
        genotype_creator.n_output_nodes,
        hidden_nodes,
        connections
    )
    return genotype
end

function create_genotypes(
    genotype_creator::RandomFCGnarlNetworkGenotypeCreator,
    rng::AbstractRNG,
    counter::Counter,
    n_population::Int
)
    genotypes = [
        create_random_fc_genotype(genotype_creator, counter, rng) for i in 1:n_population
    ]
    return genotypes
end


