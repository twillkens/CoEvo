module Basic

export BasicIndividual, BasicIndividualCreator

import ....Interfaces: create_individuals, mutate!

using ....Abstract
using ....Interfaces
using ...Phenotypes.Defaults: DefaultPhenotypeCreator

Base.@kwdef mutable struct BasicIndividual{G <: Genotype, P <: Phenotype} <: Individual
    id::Int
    parent_id::Int
    genotype::G
    phenotype::P
end


function BasicIndividual(id::Int, genotype::Genotype)
    phenotype = create_phenotype(DefaultPhenotypeCreator(), id, genotype)
    individual = BasicIndividual(id, id, genotype, phenotype)
    return individual
end

BasicIndividual(genotype::Genotype) = BasicIndividual(0, genotype)

struct BasicIndividualCreator <: IndividualCreator end

function create_individuals(::BasicIndividualCreator, n_individuals::Int, state::State)
    ids = step!(state.reproducer.individual_id_counter, n_individuals)
    genotypes = create_genotypes(
        state.reproducer.genotype_creator, n_individuals, state
    )
    phenotypes = [
        create_phenotype(state.reproducer.phenotype_creator, id, genotype) 
        for (genotype, id) in zip(genotypes, ids)
    ]
    individuals = [
        BasicIndividual(id, id, genotype, phenotype)
        for (id, genotype, phenotype) in zip(ids, genotypes, phenotypes)
    ]
    return individuals
end

function mutate!(mutator::Mutator, individual::BasicIndividual, state::State)
    mutate!(mutator, individual.genotype, state)
    individual.phenotype = create_phenotype(
        state.reproducer.phenotype_creator, individual.id, individual.genotype
    )
end

end