using ....CoEvo.Abstract: PhenotypeConfiguration
using ..Genotypes: VectorGenotype
"""
    DefaultPhenoCfg <: PhenotypeConfiguration

A default phenotype configuration struct. 
Instances of this struct indicate that the default phenotype conversion should be used.
"""
struct DefaultPhenotypeConfiguration <: PhenotypeConfiguration end

# Return the vector of values from a `VectorGeno` genotype for a given phenotype configuration.
function(pheno_cfg::DefaultPhenotypeConfiguration)(geno::VectorGenotype)
    geno.vals
end
