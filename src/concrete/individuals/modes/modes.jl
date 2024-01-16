module Modes

export ModesIndividual, ModesIndividualCreator, create_individuals

import ....Interfaces: create_individuals, convert_to_dict, create_from_dict, mutate!

using Random: AbstractRNG
using StatsBase: median
using ....Abstract
using ....Interfaces
using ....Interfaces: step!

Base.@kwdef mutable struct ModesIndividual{G <: Genotype, P <: Phenotype} <: Individual
    id::Int
    parent_id::Int
    tag::Int
    full_genotype::G
    minimized_genotype::G
    phenotype::P
end

struct ModesIndividualCreator <: IndividualCreator end

function create_individuals(::ModesIndividualCreator, n_individuals::Int, state::State)
    ids = step!(state.reproducer.individual_id_counter, n_individuals)
    full_genotypes = create_genotypes(
        state.reproducer.genotype_creator, n_individuals, state
    )
    minimized_genotypes = [minimize(genotype) for genotype in full_genotypes]
    phenotypes = [
        create_phenotype(state.reproducer.phenotype_creator, id, genotype) 
        for (genotype, id) in zip(minimized_genotypes, ids)
    ]
    individuals = [
        ModesIndividual(id, id, id, full_genotype, minimized_genotype, phenotype)
        for (id, full_genotype, minimized_genotype, phenotype) 
            in zip(ids, full_genotypes, minimized_genotypes, phenotypes)
    ]
    return individuals
end

function mutate!(mutator::Mutator, individual::ModesIndividual, state::State)
    mutate!(mutator, individual.full_genotype, state)
    individual.minimized_genotype = minimize(individual.full_genotype)
    individual.phenotype = create_phenotype(
        state.reproducer.phenotype_creator, individual.id, individual.minimized_genotype
    )
end

function convert_to_dict(individual::ModesIndividual)
    dict = Dict(
        "ID" => individual.id,
        "P" => individual.parent_id,
        "T" => individual.tag,
        "G" => convert_to_dict(individual.full_genotype),
    )
    return dict
end

function create_from_dict(::ModesIndividualCreator, dict::Dict, state::State)
    id = dict["ID"]
    parent_id = dict["P"]
    tag = dict["T"]
    full_genotype = create_from_dict(state.reproducer.genotype_creator, dict["G"], state)
    minimized_genotype = minimize(full_genotype)
    phenotype = create_phenotype(state.reproducer.phenotype_creator, id, minimized_genotype)
    individual = ModesIndividual(id, parent_id, tag, full_genotype, minimized_genotype, phenotype)
    return individual
end

end