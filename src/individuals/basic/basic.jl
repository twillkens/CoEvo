module Basic

export BasicIndividual, BasicIndividualCreator

import ..Individuals: create_individuals

using Random: AbstractRNG
using ...Counters: Counter, count!
using ...Genotypes: Genotype, GenotypeCreator, create_genotypes
using ..Individuals: Individual, IndividualCreator

struct BasicIndividual{G <: Genotype} <: Individual
    id::Int
    genotype::G
    parent_ids::Vector{Int}
end

function BasicIndividual(genotype::Genotype)
    return BasicIndividual(0, genotype, [0])
end

function BasicIndividual(id::Int, genotype::Genotype)
    return BasicIndividual(id, genotype, [id])
end

struct BasicIndividualCreator <: IndividualCreator end

function create_individuals(
    ::BasicIndividualCreator,
    rng::AbstractRNG,
    genotype_creator::GenotypeCreator,
    n_individuals::Int,
    individual_id_counter::Counter,
    gene_id_counter::Counter,
)
    genotypes = create_genotypes(
        genotype_creator, rng, gene_id_counter, n_individuals
    )
    individual_ids = count!(individual_id_counter, n_individuals)
    individuals = [
        BasicIndividual(individual_id, genotype, [individual_id]) 
        for (individual_id, genotype) in zip(individual_ids, genotypes)
    ]
    return individuals
end

end