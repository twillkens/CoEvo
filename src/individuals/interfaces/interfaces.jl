module Interfaces

using Random: AbstractRNG
using ...Counters: Counter
using ...Genotypes.Abstract: GenotypeCreator
using ..Individuals.Abstract: IndividualCreator

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

end