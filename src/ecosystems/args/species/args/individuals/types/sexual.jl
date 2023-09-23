using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration

struct SexualIndivdual{G <: Genotype} <: Individual
    id::Int
    geno::G
    parent_ids::Vector{Int}
end

struct SexualIndividualConfiguration <: IndividualConfiguration end

function(cfg::SexualIndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})
    return SexualIndividual(id, geno, parent_ids)
end

function(cfg::SexualIndividualConfiguration)(id::Int, geno::Genotype)
    return SexualIndividual(id, geno, [])
end
