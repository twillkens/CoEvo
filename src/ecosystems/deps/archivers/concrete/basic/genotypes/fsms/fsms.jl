module FiniteStateMachines

using JLD2: Group
using .....Ecosystems.Species.Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using ...Basic: BasicArchiver

import ....Archivers.Interfaces: save_genotype!

function save_genotype!(
    ::BasicArchiver, geno_group::Group, geno::FiniteStateMachineGenotype
)
    geno_group["start"] = geno.start
    geno_group["ones"] = collect(geno.ones)
    geno_group["zeros"] = collect(geno.zeros)
    keys = Tuple{geno.links}
    values = Tuple{values(geno.links)}
    geno_group["link_keys"] = keys
    geno_group["link_values"] = values
end

end