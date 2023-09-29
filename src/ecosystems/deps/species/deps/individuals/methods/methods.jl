using Random: AbstractRNG

using ....Ecosystems.Utilities.Counters: Counter
using .Abstract: IndividualCreator
using .Genotypes.Abstract: Genotype

import .Interfaces: create_individual

"""
    (creator::BasicIndividualCreator)(id::Int, geno::Genotype)

Construct a `BasicIndividual` with the specified ID `id` and genotype `geno`,
with an empty list of parent IDs.
"""
function create_individual(indiv_creator::IndividualCreator, id::Int, geno::Genotype)
    return create_individual(indiv_creator, id, geno, Int[])
end
