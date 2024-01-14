export create_individuals, get_individuals, create_phenotype
export convert_to_dictionary, convert_from_dictionary

using ..Abstract

function create_individuals(individual_creator::IndividualCreator, state::State)
    individual_creator_type = typeof(individual_creator)
    state_type = typeof(state)
    error(
        "create_individuals not implemented for $individual_creator_type " * "and $state_type"
    )
end

function create_phenotype(
    phenotype_creator::PhenotypeCreator, individual::Individual)::Phenotype
    phenotype = create_phenotype(phenotype_creator, individual.genotype, individual.id)
    return phenotype
end

function convert_to_dictionary(individual::Individual)
    error("convert_to_dictionary not implemented for $individual")
end

function convert_from_dictionary(
    individual_creator::IndividualCreator, 
    genotype_creator::GenotypeCreator,
    phenotype_creator::PhenotypeCreator,
    dict::Dict
)
    individual_creator_type = typeof(individual_creator)
    genotype_creator_type = typeof(genotype_creator)
    phenotype_creator_type = typeof(phenotype_creator)
    error("convert_from_dictionary not implemented for $individual_creator_type, " *
        "$genotype_creator_type, $phenotype_creator_type, and $dict"
    )
end