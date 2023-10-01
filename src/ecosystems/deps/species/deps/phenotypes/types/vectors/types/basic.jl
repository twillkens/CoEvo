module Basic

export BasicVectorPhenotype

using ...Phenotypes.Abstract: PhenotypeCreator
using ..Vectors.Abstract: VectorPhenotype
using ....Genotypes.Vectors.Basic: BasicVectorGenotype

import ...Interfaces: create_phenotype, act

Base.@kwdef struct BasicVectorPhenotype{T <: Real} <: VectorPhenotype
    values::Vector{T}
end

# Extract the vector of genes from a `BasicVectorGenotype` given a certain phenotype configuration.
function create_phenotype(::PhenotypeCreator, geno::BasicVectorGenotype)
    BasicVectorPhenotype(geno.genes)
end

function act(pheno::BasicVectorPhenotype, ::Any)
    pheno.values
end

end