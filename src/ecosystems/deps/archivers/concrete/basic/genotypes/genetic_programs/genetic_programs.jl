module GeneticPrograms

using JLD2: Group
using .....Ecosystems.Species.Genotypes.GeneticPrograms: GeneticProgramGenotype, ExpressionNodeGene
using ...Basic: BasicArchiver

import ....Archivers.Interfaces: save_genotype!

function save_genotype!(
    archiver::BasicArchiver,
    genotype_group::Group, 
    geno::GeneticProgramGenotype
)
    genotype_group["root_id"] = geno.root_id

    function extract_gene_data(gene::ExpressionNodeGene)
        return Dict(
            "id" => gene.id,
            "parent_id" => gene.parent_id,
            "val" => gene.val,
            "child_ids" => gene.child_ids
        )
    end

    genotype_group["functions"] = Dict(
        k => extract_gene_data(v) for (k, v) in geno.functions
    )

    genotype_group["terminals"] = Dict(
        k => extract_gene_data(v) for (k, v) in geno.terminals
    )
end


end