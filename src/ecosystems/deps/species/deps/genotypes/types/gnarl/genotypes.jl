module Genotypes

export GnarlNetworkGenotype, GnarlNetworkGenotypeCreator

using Random: AbstractRNG
using .....Ecosystems.Utilities.Counters: Counter
using ..Genes: GnarlNetworkNodeGene, GnarlNetworkConnectionGene
using ...Genotypes.Abstract: Genotype, GenotypeCreator

import ....Genotypes.Interfaces: create_genotypes

struct GnarlNetworkGenotype <: Genotype
    n_input_nodes::Int
    n_output_nodes::Int
    hidden_nodes::Vector{GnarlNetworkNodeGene}
    connections::Vector{GnarlNetworkConnectionGene}
end

struct GnarlNetworkGenotypeCreator <: GenotypeCreator
    n_input_nodes::Int
    n_output_nodes::Int
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