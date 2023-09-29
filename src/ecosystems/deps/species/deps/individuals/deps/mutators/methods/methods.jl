
using ....Ecosystems.Utilities.Counters: Counter
using .Abstract: Mutator, Individual, AbstractRNG

import .Abstract: mutate

"""
    Generic mutation function for `Individual`.

Mutate the genotype of an `Individual` using a given mutation strategy.
"""
function mutate(
    mutator::Mutator,rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: Individual}
    geno = mutate(mutator, rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_ids)
end

"""
    Batch mutation for a collection of individuals.

Apply a mutation strategy to each individual in the collection `indivs` and return the 
mutated individuals.
"""
function mutate(
    mutator::Mutator, rng::AbstractRNG, gene_id_counter::Counter, indivs::Vector{<:Individual}
)
    [mutate(mutator, rng, gene_id_counter, indiv) for indiv in indivs]
end