module Vectors

using JLD2: Group

using .....Ecosystems.Species.Genotypes.Vectors.Basic: BasicVectorGenotype
using ...Basic: BasicArchiver

import ....Archivers.Interfaces: save_genotype!

function save_genotype!(
    archiver::BasicArchiver, 
    genotype_group::Group, 
    geno::BasicVectorGenotype
)
    genotype_group["genes"] = geno.genes
end

end