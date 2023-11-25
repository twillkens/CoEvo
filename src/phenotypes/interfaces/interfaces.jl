export create_phenotype, act!, reset!

function create_phenotype(phenotype_creator::PhenotypeCreator, genotype::Genotype, id::Int)
    throw(ErrorException(
        "Default phenotype creation for $phenotype_creator and $genotype not implemented for $id."
    ))
end

function create_phenotype(phenotype_creator::PhenotypeCreator, genotype::Genotype)
    return create_phenotype(phenotype_creator, genotype, 0)
end

function create_phenotype(
    phenotype_creator::PhenotypeCreator, individual::Individual)::Phenotype
    phenotype = create_phenotype(phenotype_creator, individual.genotype, individual.id)
    return phenotype
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