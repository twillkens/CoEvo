module Modes

export ModesIndividual, ModesIndividualCreator, create_individuals

import ....Interfaces: create_individuals, convert_to_dictionary, convert_from_dictionary

using Random: AbstractRNG
using StatsBase: median
using ....Abstract
using ....Interfaces
using ....Interfaces: count!

struct ModesIndividual{G <: Genotype, P <: Phenotype} <: Individual
    id::Int
    parent_id::Int
    tag::Int
    full_genotype::G
    minimized_genotype::G
    phenotype::P
end

struct ModesIndividualCreator <: IndividualCreator end

function create_individuals(::ModesIndividualCreator, state::State)
    ids = count!(state.individual_id_counter, state.n_population)
    full_genotypes = create_genotypes(state.genotype_creator, state)
    minimized_genotypes = [minimize(genotype) for genotype in full_genotypes]
    phenotypes = [
        create_phenotype(state.phenotype_creator, genotype, id) 
        for (genotype, id) in zip(minimized_genotypes, ids)
    ]
    individuals = [
        ModesIndividual(id, id, id, full_genotype, minimized_genotype, phenotype)
        for (id, full_genotype, minimized_genotype, phenotype) 
            in zip(ids, full_genotypes, minimized_genotypes, phenotypes)
    ]
    return individuals
end

function convert_to_dictionary(individual::ModesIndividual)
    return Dict(
        "I" => individual.id,
        "P" => individual.parent_id,
        "T" => individual.tag,
        "G" => convert_to_dictionary(individual.full_genotype),
    )
end

function convert_from_dictionary(
    dict::Dict, 
    ::ModesIndividualCreator,
    genotype_creator::GenotypeCreator, 
    phenotype_creator::PhenotypeCreator
)
    id = dict["I"]
    parent_id = dict["P"]
    tag = dict["T"]
    full_genotype = convert_from_dictionary(genotype_creator, dict["G"],)
    minimized_genotype = minimize(full_genotype)
    phenotype = create_phenotype(phenotype_creator, minimized_genotype, id)
    return ModesIndividual(id, parent_id, tag, full_genotype, minimized_genotype, phenotype)
end

end