using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration

struct SexualIndiv{G <: Genotype} <: Individual
    id::Int
    geno::G
    parent_ids::Vector{Int}
end

struct SexualIndivCfg <: IndividualConfiguration end

function(cfg::SexualIndivCfg)(id::Int, geno::Genotype, parent_ids::Vector{Int})
    return SexualIndiv(id, geno, parent_ids)
end

function(cfg::SexualIndivCfg)(id::Int, geno::Genotype)
    return SexualIndiv(id, geno, [])
end
