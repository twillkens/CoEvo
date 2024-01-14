module Basic

export BasicReproducer

using ....Abstract

@kwdef mutable struct BasicReproducer{
    G <: GenotypeCreator,
    C <: Counter,
    P <: PhenotypeCreator,
    I <: IndividualCreator,
    R <: Recombiner,
    M <: Mutator,
    S1 <: Selector,
    S2 <: SpeciesCreator,
    E <: EcosystemCreator
} <: Reproducer
    species_ids::Vector{String}
    gene_id_counter::C
    genotype_creator::G
    recombiner::R
    mutator::M
    phenotype_creator::P
    individual_id_counter::C
    individual_creator::I
    selector::S1
    species_creator::S2
    ecosystem_creator::E
end

end