module Vectors

export BasicVectorGenotypeLoader

using JLD2: Group
using ....Ecosystems.Species.Genotypes.Vectors.Basic: BasicVectorGenotype   
using ...Loaders.Abstract: Loader

import ...Loaders.Interfaces: load_genotype

struct BasicVectorGenotypeLoader <: Loader end

function load_genotype(::BasicVectorGenotypeLoader, genotype_group::Group)
    genes = genotype_group["genes"]
    return BasicVectorGenotype(genes)
end

end