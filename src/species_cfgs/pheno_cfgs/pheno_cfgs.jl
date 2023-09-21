module PhenotypeConfigurations

export DefaultPhenoCfg

using ...CoEvo: Genotype, PhenotypeConfiguration

"""
    DefaultPhenoCfg <: PhenotypeConfiguration

A default phenotype configuration struct. 
Instances of this struct indicate that the default phenotype conversion should be used.
"""
struct DefaultPhenoCfg <: PhenotypeConfiguration end

"""
    (cfg::PhenotypeConfiguration)(::Genotype)

Throws an error indicating that the default phenotype conversion is not implemented for the given genotype.
"""
function (cfg::PhenotypeConfiguration)(::Genotype)
    throw(ErrorException("Default phenotype conversion not implemented for genotype."))
end

end