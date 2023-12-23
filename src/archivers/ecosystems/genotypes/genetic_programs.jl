using ...Genotypes.GeneticPrograms: GeneticProgramGenotype, ExpressionNode

function save_genotype!(
    ::GenotypeArchiver,
    genotype_group::Group, 
    geno::GeneticProgramGenotype
)
    genotype_group["root_id"] = geno.root_id

    function extract_gene_data(gene::ExpressionNode)
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
