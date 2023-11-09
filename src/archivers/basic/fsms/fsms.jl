using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotypeCreator

function save_genotype!(
    ::BasicArchiver, genotype_group::Group, genotype::FiniteStateMachineGenotype
)
    genotype_group["start"] = genotype.start
    genotype_group["ones"] = collect(genotype.ones)
    genotype_group["zeros"] = collect(genotype.zeros)
    keys = Tuple{genotype.links}
    values = Tuple{values(genotype.links)}
    genotype_group["link_keys"] = keys
    genotype_group["link_values"] = values
end

function load_genotype(::FiniteStateMachineGenotypeCreator, genotype_group::Group)
    start = genotype_group["start"]
    ones = Set(genotype_group["ones"])
    zeros = Set(genotype_group["zeros"])
    keys = genotype_group["link_keys"]
    values = genotype_group["link_values"]
    links = Dict(zip(keys, values))
    genotype = FiniteStateMachineGenotype(start, ones, zeros, links)
    return genotype
end