module Interfaces 

export mutate

using .....Ecosystems.Utilities.Counters: Counter
using ..Abstract: Mutator, Genotype, AbstractRNG

"""
    Generic mutation function for `Individual`.

Mutate the genotype of an `Individual` using a given mutation strategy.
"""
function mutate(
    mutator::Mutator, 
    rng::AbstractRNG, 
    gene_id_counter::Counter,
    genotype::Genotype
)::Genotype
    throw(ErrorException("Default mutation for $mutator not implemented for $genotype."))
end

end