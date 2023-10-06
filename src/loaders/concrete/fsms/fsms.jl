module FiniteStateMachines

export FiniteStateMachineGenotypeLoader

using JLD2: Group
using ....Ecosystems.Species.Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ...Loaders.Abstract: Loader

import ...Loaders.Interfaces: load_genotype

struct FiniteStateMachineGenotypeLoader <: Loader end

function load_genotype(::FiniteStateMachineGenotypeLoader, geno_group::Group)
    start = geno_group["start"]
    ones = Set(geno_group["ones"])
    zeros = Set(geno_group["zeros"])
    keys = geno_group["link_keys"]
    values = geno_group["link_values"]
    links = Dict(zip(keys, values))
    genotype = FiniteStateMachineGenotype(start, ones, zeros, links)
    return genotype
end

end