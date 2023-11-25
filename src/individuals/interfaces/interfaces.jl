export create_individuals, get_individuals

function create_individuals(
    individual_creator::IndividualCreator,
    random_number_generator::AbstractRNG,
    genotype_creator::GenotypeCreator,
    n_individuals::Int,
    individual_id_counter::Counter,
    gene_id_counter::Counter,
)
    individual_creator_type = typeof(individual_creator)
    genotype_creator_type = typeof(genotype_creator)
    throw(ErrorException("create_individuals not implemented for $individual_creator_type and $genotype_creator_type"))
end

function get_individuals(individuals::Vector{<:Individual}, ids::Vector{Int})
    individuals = filter(individual -> individual.id in ids, individuals)
    if length(individuals) != length(ids)
        throw(ErrorException("Could not find all individuals with ids $ids"))
    end
    return individuals
end