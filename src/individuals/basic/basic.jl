module Basic

export BasicIndividual, BasicIndividualCreator

import ..Individuals.Interfaces: create_individuals

using Random: AbstractRNG
using ...Counters: Counter, next!
using ...Genotypes.Abstract: GenotypeCreator
using ...Genotypes.Interfaces: create_genotypes
using ..Individuals.Abstract: Individual, IndividualCreator

struct BasicIndividual{G <: Genotype} <: Individual
    id::Int
    genotype::G
    parent_ids::Vector{Int}
end

struct BasicIndividualCreator <: IndividualCreator end

function create_individuals(
    ::BasicIndividualCreator,
    random_number_generator::AbstractRNG,
    genotype_creator::GenotypeCreator,
    n_individuals::Int,
    individual_id_counter::Counter,
    gene_id_counter::Counter,
)
    genotypes = create_genotypes(
        genotype_creator, random_number_generator, gene_id_counter, n_individuals
    )
    individual_ids = next!(individual_id_counter, length(genotypes))
    individuals = [
        BasicIndividual(individual_id, genotype, Int[]) 
        for (individual_id, genotype) in zip(individual_ids, genotypes)
    ]
    return individuals
end

end