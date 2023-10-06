module GeneticPrograms

export GeneticProgramGenotypeLoader

using JLD2: Group
using ....Ecosystems.Species.Genotypes.GeneticPrograms: GeneticProgramGenotype, ExpressionNodeGene
using ...Loaders.Abstract: Loader

import ...Loaders.Interfaces: load_genotype

struct GeneticProgramGenotypeLoader <: Loader end

function load_genotype(::GeneticProgramGenotypeLoader, genotype_group::Group)
    root_id = genotype_group["root_id"]

    function construct_gene(data::Dict)
        return ExpressionNodeGene(data["id"], data["parent_id"], data["val"], data["child_ids"])
    end

    functions = Dict(
        k => construct_gene(v) for (k, v) in genotype_group["functions"]
    )

    terminals = Dict(
        k => construct_gene(v) for (k, v) in genotype_group["terminals"]
    )

    return GeneticProgramGenotype(root_id = root_id, functions = functions, terminals = terminals)
end

end