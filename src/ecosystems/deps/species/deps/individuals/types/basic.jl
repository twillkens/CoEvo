export BasicIndividual, BasicIndividualCreator

using ...Ecosystems.Abstract: Archiver
using ...Ecosystems.Utilities.Counters: Counter
using .Abstract: Genotype, GenotypeCreator, Phenotype, PhenotypeCreator
using .Abstract: Individual, IndividualCreator, Mutator

import .Abstract: create_individual

"""
    BasicIndividual{G <: Genotype}

Representation of an individual within a species, characterized by having a 
unique ID and a genotype along with a list of parent IDs.

# Fields
- `id::Int`: The unique identifier for the individual.
- `geno::G`: The genotype of the individual.
- `parent_ids::Vector{Int}`: The ID(s) of the parent(s) of the individual.
"""
struct BasicIndividual{G <: Genotype} <: Individual
    id::Int
    geno::G
    parent_ids::Vector{Int}
end

"""
    BasicIndividualCreator

Creator for constructing instances of `BasicIndividual`.
"""
Base.@kwdef struct BasicIndividualCreator{
    G <: GenotypeCreator, 
    P <: PhenotypeCreator, 
    M <: Mutator
} <: IndividualCreator 
    geno_creator::G
    pheno_creator::P
    mutators::Vector{M}
end

"""
    (creator::BasicIndividualCreator)(id::Int, geno::Genotype, parent_ids::Vector{Int})

Construct a `BasicIndividual` with the specified ID `id`, genotype `geno`, 
and parent IDs `parent_ids`.
"""
function create_individual(
    ::BasicIndividualCreator, id::Int, geno::Genotype, parent_ids::Vector{Int}
)
    return BasicIndividual(id, geno, parent_ids)
end