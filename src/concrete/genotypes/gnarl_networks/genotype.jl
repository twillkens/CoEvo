export NodeGene, ConnectionGene
export GnarlNetworkGenotype, GnarlNetworkGenotypeCreator

import ....Interfaces: create_genotypes
using ....Abstract: Gene, Genotype, GenotypeCreator, Counter, AbstractRNG
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
Base.@kwdef struct GnarlNetworkGenotype <: Genotype
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
    ::AbstractRNG,
    ::Counter,
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
