export AsexualIndividual, AsexualIndividualConfiguration

using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration

"""
    AsexualIndividual{G <: Genotype} <: Individual

A representation of an asexual individual in the context of a coevolutionary algorithm.

This struct captures the key properties of an asexual individual including its unique identifier, 
its genotype, and the identifier of its parent.

# Fields
- `id::Int`: A unique identifier for the individual.
- `geno::G`: The genotype of the individual, parameterized by a type `G` that is a subtype of `Genotype`.
- `parent_id::Int`: The identifier of the individual's parent. If the individual was seeded (i.e., not 
  produced from a parent), this ID is 0.
"""
struct AsexualIndividual{G <: Genotype} <: Individual
    id::Int
    geno::G
    parent_id::Int
end

"""
    AsexualIndividualConfiguration <: IndividualConfiguration

Configuration type specific to creating `AsexualIndividual`s. Used in conjunction with the 
associated constructor functions.
"""
struct AsexualIndividualConfiguration <: IndividualConfiguration end

"""
    (indiv_cfg::AsexualIndividualConfiguration)(id::Int, geno::Genotype, parent_id::Int)

Creates a new `AsexualIndividual` with the provided `id`, `geno`, and `parent_id`.

# Arguments
- `id::Int`: A unique identifier for the new individual.
- `geno::Genotype`: The genotype of the new individual.
- `parent_id::Int`: The identifier of the individual's parent.

# Returns
- An `AsexualIndividual` with the specified attributes.
"""
function(indiv_cfg::AsexualIndividualConfiguration)(id::Int, geno::Genotype, parent_id::Int)
    return AsexualIndividual(id, geno, parent_id)
end

"""
    (indiv_cfg::AsexualIndividualConfiguration)(id::Int, geno::Genotype)

Creates a new `AsexualIndividual` with the provided `id` and `geno`, assuming it's a seeded 
individual (with `parent_id` set to 0).

# Arguments
- `id::Int`: A unique identifier for the new individual.
- `geno::Genotype`: The genotype of the new individual.

# Returns
- An `AsexualIndividual` with `parent_id` set to 0 and other attributes as specified.
"""
function(indiv_cfg::AsexualIndividualConfiguration)(id::Int, geno::Genotype)
    return AsexualIndividual(id, geno, 0)
end


