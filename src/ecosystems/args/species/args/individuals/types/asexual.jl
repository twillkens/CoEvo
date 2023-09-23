using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration

"""
    Indiv{G <: Genotype} <: Individual

Represents an individual with a genotype, an identifier, and a parent identifier.

# Fields
- `id::Int`: The unique identifier for the individual.
- `geno::G`: The genotype of the individual.
- `pid::Int`: Identifier of the parent. It's `0` if the individual does not have a known parent.
"""
struct AsexualIndividual{G <: Genotype} <: Individual
    id::Int
    geno::G
    parent_id::Int
end

struct AsexualIndividualConfiguration <: IndividualConfiguration end

function(cfg::AsexualIndividualConfiguration)(id::Int, geno::Genotype, parent_id::Int)
    return AsexualIndividual(id, geno, parent_id)
end

function(cfg::AsexualIndividualConfiguration)(id::Int, geno::Genotype)
    return AsexualIndividual(id, geno, 0)
end
