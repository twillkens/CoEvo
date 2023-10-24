module Vectors

using JLD2: Group

using .....Ecosystems.Species.Genotypes.Vectors.Basic: BasicVectorGenotype
using ...Basic: BasicArchiver

import ....Archivers.Interfaces: save_genotype!

function save_genotype!(
    archiver::BasicArchiver, 
    genotype_group::Group, 
    genotype::BasicVectorGenotype
)
    genotype_group["genes"] = genotype.genes
end

end