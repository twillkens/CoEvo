module Individuals

export AsexualIndividual, AsexualIndividualConfiguration
export SexualIndivdual, SexualIndividualConfiguration


include("types/asexual.jl")
include("types/sexual.jl")


using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration

function(indiv_cfg::IndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})
    if length(parent_ids) == 1
        return AsexualIndividual(id, geno, parent_ids[1])
    else
        return SexualIndividual(id, geno, parent_ids)
    end
end

end