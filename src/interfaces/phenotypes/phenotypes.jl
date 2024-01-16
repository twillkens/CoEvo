export create_phenotype, act!, reset! 

using ..Abstract

function create_phenotype(phenotype_creator::PhenotypeCreator, id::Int, genotype::Genotype)
    phenotype_creator = typeof(phenotype_creator)
    id = typeof(id)
    genotype = typeof(genotype)
    error("Default phenotype creation for $phenotype_creator, $id, $genotype not implemented.")
end

function create_phenotype(phenotype_creator::PhenotypeCreator, genotype::Genotype)
    return create_phenotype(phenotype_creator, 0, genotype)
end

function act!(phenotype::Phenotype, args::Any)
    phenotype = typeof(phenotype)
    args = typeof(args)
    error("act! not implemented for $phenotype with args $args")
end

function act!(phenotype::Phenotype)
    return act!(phenotype, nothing)
end

function reset!(phenotype::Phenotype)
    phenotype = typeof(phenotype)
    error("reset! not implemented for $phenotype")
end