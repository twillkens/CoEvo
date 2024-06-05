module Modes

export ModesIndividual, ModesIndividualCreator, create_individuals, mutate!, reset_tags!

import ....Interfaces: create_individuals, convert_to_dict, create_from_dict, mutate!
using ....Abstract
using ....Interfaces

Base.@kwdef mutable struct ModesIndividual{G <: Genotype, P <: Phenotype} <: Individual
    id::Int
    parent_id::Int
    tag::Int
    genotype::G
    phenotype::P
end

struct ModesIndividualCreator <: IndividualCreator end

function create_individuals(::ModesIndividualCreator, n_individuals::Int, state::State)
    ids = step!(state.reproducer.individual_id_counter, n_individuals)
    genotypes = create_genotypes(
        state.reproducer.genotype_creator, n_individuals, state
    )
    phenotypes = [
        create_phenotype(state.reproducer.phenotype_creator, id, genotype) 
        for (genotype, id) in zip(genotypes, ids)
    ]
    individuals = [
        ModesIndividual(id, id, id, full_genotype, phenotype)
        for (id, full_genotype, phenotype) in zip(ids, genotypes, phenotypes)
    ]
    return individuals
end

function mutate!(
    mutator::Mutator, 
    individual::ModesIndividual, 
    reproducer::Reproducer, 
    state::State
)
    mutate!(mutator, individual.genotype, state)
    individual.phenotype = create_phenotype(
        reproducer.phenotype_creator, individual.id, individual.genotype
    )
end

function reset_tags!(individuals::Vector{<:ModesIndividual})
    for individual in individuals
        individual.tag = individual.id
    end
end

end