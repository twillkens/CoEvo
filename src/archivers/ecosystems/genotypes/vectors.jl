using ...Genotypes.Vectors: BasicVectorGenotype

function archive!(::GenotypeArchiver, genotype::BasicVectorGenotype, genotype_group::Group)
    genotype_group["genes"] = genotype.genes
end
