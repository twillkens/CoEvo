using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration

"""
    Indiv{G <: Genotype} <: Individual

Represents an individual with a genotype, an identifier, and a parent identifier.

# Fields
- `id::Int`: The unique identifier for the individual.
- `geno::G`: The genotype of the individual.
- `pid::Int`: Identifier of the parent. It's `0` if the individual does not have a known parent.
"""
struct AsexualIndiv{G <: Genotype} <: Individual
    id::Int
    geno::G
    parent_id::Int
end

struct AsexualIndivCfg <: IndividualConfiguration end

function(cfg::AsexualIndivCfg)(id::Int, geno::Genotype, parent_id::Int)
    return AsexualIndiv(id, geno, parent_id)
end

function(cfg::AsexualIndivCfg)(id::Int, geno::Genotype)
    return AsexualIndiv(id, geno, 0)
end
