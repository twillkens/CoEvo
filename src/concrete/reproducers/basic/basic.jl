module Basic

export BasicReproducer

import ....Interfaces: create_species
using ....Abstract
using Base: @kwdef

@kwdef mutable struct BasicReproducer{
    G <: GenotypeCreator,
    P <: PhenotypeCreator,
    I <: IndividualCreator,
    R <: Recombiner,
    M <: Mutator,
    S1 <: Selector,
    S2 <: SpeciesCreator,
} <: Reproducer
    id::String
    genotype_creator::G
    phenotype_creator::P
    individual_creator::I
    species_creator::S2
    selector::S1
    recombiner::R
    mutator::M
end

function create_species(reproducer::BasicReproducer, state::State)
    species = create_species(reproducer.species_creator, reproducer, state)
    return species
end

end