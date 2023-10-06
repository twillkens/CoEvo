module Genotypes

export GnarlNetworkGenotype, GnarlNetworkGenotypeCreator

using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter
using ..Genes: GnarlNetworkNodeGene, GnarlNetworkConnectionGene
using ...Genotypes.Abstract: Genotype, GenotypeCreator

import ....Genotypes.Interfaces: create_genotypes

Base.@kwdef struct GnarlNetworkGenotype <: Genotype
    n_input_nodes::Int
    n_output_nodes::Int
    hidden_nodes::Vector{GnarlNetworkNodeGene}
    connections::Vector{GnarlNetworkConnectionGene}
end

function Base.show(io::IO, genotype::GnarlNetworkGenotype)
    println(io, "GnarlNetwork Genotype(#Input Nodes: $(genotype.n_input_nodes), #Output Nodes: $(genotype.n_output_nodes))")
    
    println(io, "Hidden Nodes:")
    for node in genotype.hidden_nodes
        println(io, "   ", node)
    end
    
    println(io, "Connections:")
    for connection in genotype.connections
        println(io, "   ", connection)
    end
end

Base.@kwdef struct GnarlNetworkGenotypeCreator <: GenotypeCreator
    n_input_nodes::Int
    n_output_nodes::Int
end

function Base.show(io::IO, creator::GnarlNetworkGenotypeCreator)
    println(io, "GnarlNetwork Genotype Creator(#Input Nodes: $(creator.n_input_nodes), #Output Nodes: $(creator.n_output_nodes))")
end

function create_genotypes(
    genotype_creator::GnarlNetworkGenotypeCreator,
    ::AbstractRNG,
    ::Counter,
    n_pop::Int
)
    genotypes = [
        GnarlNetworkGenotype(
            genotype_creator.n_input_nodes,
            genotype_creator.n_output_nodes,
            Vector{GnarlNetworkNodeGene}(),
            Vector{GnarlNetworkConnectionGene}()
        ) for i in 1:n_pop
    ]

    return genotypes
end

end