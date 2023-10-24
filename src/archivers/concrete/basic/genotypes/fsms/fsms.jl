module FiniteStateMachines

using JLD2: Group
using .....Ecosystems.Species.Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ...Basic: BasicArchiver

import ....Archivers.Interfaces: save_genotype!

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

end