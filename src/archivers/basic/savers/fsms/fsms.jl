using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotype

function save_genotype!(
    ::BasicArchiver, geno_group::Group, genotype::FiniteStateMachineGenotype
)
    geno_group["start"] = genotype.start
    geno_group["ones"] = collect(genotype.ones)
    geno_group["zeros"] = collect(genotype.zeros)
    keys = Tuple{genotype.links}
    values = Tuple{values(genotype.links)}
    geno_group["link_keys"] = keys
    geno_group["link_values"] = values
end
