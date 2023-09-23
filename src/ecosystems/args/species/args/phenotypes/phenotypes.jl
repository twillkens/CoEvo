module Phenotypes

export DefaultPhenoCfg


include("types/default.jl")

using ...CoEvo.Abstract: PhenotypeConfiguration, Genotype


"""
    (cfg::PhenotypeConfiguration)(::Genotype)

Throws an error indicating that the default phenotype conversion is not implemented for the given genotype.
"""
function (cfg::PhenotypeConfiguration)(::Genotype)
    throw(ErrorException("Default phenotype conversion not implemented for genotype."))
end


end