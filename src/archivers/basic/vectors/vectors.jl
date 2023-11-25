using ...Genotypes.Vectors: BasicVectorGenotype

function archive!(::BasicArchiver, genotype::BasicVectorGenotype, genotype_group::Group)
    genotype_group["genes"] = genotype.genes
end
