module Interfaces 

export mutate

using Random: AbstractRNG
using ...Counters: Counter
using ..Mutators.Abstract: Mutator, Genotype

"""
    Generic mutation function for `Individual`.

Mutate the genotype of an `Individual` using a given mutation strategy.
"""
function mutate(
    mutator::Mutator, 
    random_number_generator::AbstractRNG, 
    gene_id_counter::Counter,
    genotype::Genotype
)::Genotype
    throw(ErrorException("Default mutation for $mutator not implemented for $genotype."))
end

using ...Individuals.Abstract: Individual

function mutate(
    mutator::Mutator,
    random_number_generator::AbstractRNG,
    gene_id_counter::Counter,
    individuals::Vector{<:Individual},
)
    individuals = [
        Individual(
            individual.id,
            mutate(mutator, random_number_generator, gene_id_counter, individual.genotype),
            individual.parent_ids
        ) for individual in individuals
    ]

    return individuals
end

end