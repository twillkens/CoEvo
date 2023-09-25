"""
    SexualIndividual{G <: Genotype}

Representation of an individual that originates from sexual reproduction, 
characterized by having multiple parents.

# Fields
- `id::Int`: The unique identifier for the individual.
- `geno::G`: The genotype of the individual.
- `parent_ids::Vector{Int}`: The IDs of the parents of the individual.
"""
struct SexualIndividual{G <: Genotype} <: Individual
    id::Int
    geno::G
    parent_ids::Vector{Int}
end

"""
    SexualIndividualConfiguration

Configuration for constructing instances of `SexualIndividual`.
"""
struct SexualIndividualConfiguration <: IndividualConfiguration end

"""
    (cfg::SexualIndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})

Construct a `SexualIndividual` with the specified ID `id`, genotype `geno`, 
and parent IDs `parent_ids`.
"""
function(cfg::SexualIndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})
    return SexualIndividual(id, geno, parent_ids)
end

"""
    (cfg::SexualIndividualConfiguration)(id::Int, geno::Genotype)

Construct a `SexualIndividual` with the specified ID `id` and genotype `geno`,
with an empty list of parent IDs.
"""
function(cfg::SexualIndividualConfiguration)(id::Int, geno::Genotype)
    return SexualIndividual(id, geno, Int[])
end
