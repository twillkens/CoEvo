module PhenotypeConfigurations

export DefaultPhenoCfg

using ...CoEvo: Genotype, PhenotypeConfiguration

"""
    struct DefaultPhenoCfg <: PhenotypeConfiguration

Create a default phenotype configuration.
"""
struct DefaultPhenoCfg <: PhenotypeConfiguration end

function (cfg::PhenotypeConfiguration)(::Genotype)
    throw(ErrorException("Default phenotype conversion not implemented for genotype."))
end

end