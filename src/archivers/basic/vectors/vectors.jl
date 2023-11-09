using ...Genotypes.Vectors: BasicVectorGenotype

function save_genotype!(
    archiver::BasicArchiver, 
    genotype_group::Group, 
    genotype::BasicVectorGenotype
)
    genotype_group["genes"] = genotype.genes
end
