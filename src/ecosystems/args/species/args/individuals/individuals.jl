module Individuals

export AsexualIndivCfg, SexualIndivCfg

using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration

include("types/asexual.jl")
include("types/sexual.jl")

function(indiv_cfg::IndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})
    if length(parent_ids) == 1
        return AsexualIndiv(id, geno, parent_ids[1])
    else
        return SexualIndiv(id, geno, parent_ids)
    end
end

end