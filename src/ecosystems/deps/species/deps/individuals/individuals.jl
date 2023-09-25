"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system. This includes both asexual and sexual individuals 
with their associated configurations and functionalities.
"""
module Individuals

export AsexualIndividual, AsexualIndividualConfiguration
export SexualIndividual, SexualIndividualConfiguration

include("types/asexual.jl")
include("types/sexual.jl")

using Random: AbstractRNG
using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration, Mutator
using ....CoEvo.Utilities.Counters: Counter

"""
    (indiv_cfg::IndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})

Construct an instance of an individual based on the configuration `indiv_cfg`, its ID `id`,
its genotype `geno`, and the IDs of its parent(s) `parent_ids`.

For single parent ID, an `AsexualIndividual` is returned. 
For multiple parent IDs, a `SexualIndividual` is returned.
"""
function(indiv_cfg::IndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})
    if length(parent_ids) == 1
        return AsexualIndividual(id, geno, parent_ids[1])
    else
        return SexualIndividual(id, geno, parent_ids)
    end
end

"""
    Mutation function for `AsexualIndividual`.

Mutate the genotype of an `AsexualIndividual` using a given mutation strategy.
"""
function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: AsexualIndividual}
    geno = mutator(rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_id)
end

"""
    Mutation function for `SexualIndividual`.

Mutate the genotype of a `SexualIndividual` using a given mutation strategy.
"""
function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: SexualIndividual}
    geno = mutator(rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_ids)
end

"""
    Batch mutation for a collection of individuals.

Apply a mutation strategy to each individual in the collection `indivs` and return the 
mutated individuals.
"""
function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indivs::Vector{<:Individual}
)
    [mutator(rng, gene_id_counter, indiv) for indiv in indivs]
end

end
