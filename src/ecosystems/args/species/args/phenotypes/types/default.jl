using ...CoEvo.Abstract: PhenotypeConfiguration
using ..Genotypes: VectorGeno
"""
    DefaultPhenoCfg <: PhenotypeConfiguration

A default phenotype configuration struct. 
Instances of this struct indicate that the default phenotype conversion should be used.
"""
struct DefaultPhenoCfg <: PhenotypeConfiguration end

# Return the vector of values from a `VectorGeno` genotype for a given phenotype configuration.
function(pheno_cfg::DefaultPhenoCfg)(geno::VectorGeno)
    geno.vals
end
