export create_phenotype, act!, reset!, get_phenotype_state

using ..Abstract

function create_phenotype(phenotype_creator::PhenotypeCreator, genotype::Genotype, id::Int)
    throw(ErrorException(
        "Default phenotype creation for $phenotype_creator and $genotype not implemented for $id."
    ))
end

function create_phenotype(phenotype_creator::PhenotypeCreator, genotype::Genotype)
    return create_phenotype(phenotype_creator, genotype, 0)
end

function act!(phenotype::Phenotype, args...)
    throw(ErrorException("act! not implemented for $phenotype with args $args"))
end

function act!(phenotype::Phenotype)
    return act!(phenotype, nothing)
end

function reset!(phenotype::Phenotype)
    throw(ErrorException("reset! not implemented for $phenotype"))
end

function get_phenotype_state(phenotype::Phenotype)
    throw(ErrorException("get_phenotype_state not implemented for $phenotype"))
end