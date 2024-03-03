module Dodo

export DodoIndividual, DodoIndividualCreator

import ....Interfaces: create_individuals, mutate!

using ....Abstract
using ....Interfaces
using ...Phenotypes.Defaults: DefaultPhenotypeCreator

Base.@kwdef mutable struct DodoIndividual{G <: Genotype, P <: Phenotype} <: Individual
    id::Int
    parent_ids::Vector{Int}
    age::Int
    temperature::Int
    genotype::G
    phenotype::P
end

function Base.getproperty(individual::DodoIndividual, property::Symbol)
    if property == :parent_id
        if length(individual.parent_ids) != 1
            error("DodoIndividual has more than one parent")
        end
        return first(individual.parent_ids)
    else
        return getfield(individual, property)
    end
end

function Base.setproperty!(individual::DodoIndividual, property::Symbol, value)
    if property == :parent_id
        individual.parent_ids = [value]
    else
        setfield!(individual, property, value)
    end
end 

function DodoIndividual(id::Int, genotype::Genotype, phenotype_creator::PhenotypeCreator)
    phenotype = create_phenotype(phenotype_creator, id, genotype)
    individual = DodoIndividual(id, [id], 0, 1, genotype, phenotype)
    return individual
end

function DodoIndividual(
    id::Int, parent_ids::Vector{Int}, genotype::Genotype, phenotype_creator::PhenotypeCreator
)
    phenotype = create_phenotype(phenotype_creator, id, genotype)
    individual = DodoIndividual(id, parent_ids, 0, 1, genotype, phenotype)
    return individual
end

function DodoIndividual(
    id::Int, parent_id::Int, genotype::Genotype, phenotype_creator::PhenotypeCreator
)
    individual = DodoIndividual(id, [parent_id], genotype, phenotype_creator)
    return individual
end

DodoIndividual(genotype::Genotype) = DodoIndividual(0, genotype)

Base.@kwdef struct DodoIndividualCreator <: IndividualCreator 
    starting_temperature::Int = 1
end
    
function create_individuals(
    individual_creator::DodoIndividualCreator, 
    n_individuals::Int, 
    reproducer::Reproducer,
    state::State
)
    ids = step!(state.individual_id_counter, n_individuals)
    genotypes = create_genotypes(reproducer.genotype_creator, n_individuals, state)
    phenotypes = [
        create_phenotype(reproducer.phenotype_creator, id, genotype) 
        for (genotype, id) in zip(genotypes, ids)
    ]
    starting_temperature = individual_creator.starting_temperature
    individuals = [
        DodoIndividual(id, [0], 0, starting_temperature, genotype, phenotype)
        for (id, genotype, phenotype) in zip(ids, genotypes, phenotypes)
    ]
    return individuals
end

function mutate!(
    mutator::Mutator, 
    individual::DodoIndividual, 
    reproducer::Reproducer, 
    state::State
)
    n_mutations = rand(state.rng, 1:individual.temperature)
    for _ in 1:n_mutations
        mutate!(mutator, individual.genotype, state)
    end
    individual.phenotype = create_phenotype(
        reproducer.phenotype_creator, individual.id, individual.genotype
    )
end

end