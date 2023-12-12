module AdaptiveArchive

export AdaptiveArchiveSpeciesCreator

import ...Individuals: get_individuals
import ...SpeciesCreators: create_species, get_phenotype_creator, get_evaluator

using Random: AbstractRNG
using StatsBase: sample
using DataStructures: OrderedDict
using ...Counters: Counter
using ...Evaluators: Evaluator, Evaluation
using ...Evaluators.AdaptiveArchive: AdaptiveArchiveEvaluator, AdaptiveArchiveEvaluation
using ...SpeciesCreators: SpeciesCreator
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Species.AdaptiveArchive: AdaptiveArchiveSpecies

Base.@kwdef struct AdaptiveArchiveSpeciesCreator{
    B <: BasicSpeciesCreator, E <: AdaptiveArchiveEvaluator
} <: SpeciesCreator
    id::String
    max_archive_size::Int
    n_sample::Int
    basic_species_creator::B
    evaluator::E
end

function create_species(
    species_creator::AdaptiveArchiveSpeciesCreator,
    rng::AbstractRNG, 
    individual_id_counter::Counter,
    gene_id_counter::Counter
)
    basic_species = create_species(
        species_creator.basic_species_creator, rng, individual_id_counter, gene_id_counter
    )
    I = typeof(basic_species).parameters[1]
    species = AdaptiveArchiveSpecies(
        species_creator.id, 
        species_creator.max_archive_size, 
        species_creator.n_sample,
        basic_species, 
        I[], 
        Int[], 
    )
    return species
end

using Random, Distributions
using StatsBase: sample, Weights

function sample_without_replacement(
    rng::AbstractRNG, 
    vec::Vector{R}, 
    n_samples::Int,  
    weights::Vector{<:Real} = collect(1:length(vec))
) where R <: Real
    if length(vec) == 0
        return Int[]
    end
    # Ensure that n_samples is not greater than the length of the vector
    if n_samples > length(vec)
        error("Number of samples requested is greater than the length of the vector.")
    end

    # Create a weights vector proportional to the order in the vector
    #weights = 1:length(vec)

    # Normalize the weights to sum to 1 and convert to a regular array
    normalized_weights = collect(weights / sum(weights))

    # Create an empty array for the sampled values
    sampled_values = Vector{typeof(vec[1])}()

    # Copy the original vector to manipulate it
    temp_vec = copy(vec)

    for _ in 1:n_samples
        # Sample an index based on the weighted probability
        index = sample(rng, 1:length(temp_vec), Weights(normalized_weights))

        # Append the selected value to the result
        push!(sampled_values, temp_vec[index])

        # Remove the selected value and its weight from the temporary vector and weights
        deleteat!(temp_vec, index)
        deleteat!(normalized_weights, index)

        # Renormalize the weights if there are remaining elements
        if sum(normalized_weights) != 0
            normalized_weights /= sum(normalized_weights)
        end
    end

    return sampled_values
end


using ...Genotypes: get_size

function create_species(
    species_creator::AdaptiveArchiveSpeciesCreator,
    rng::AbstractRNG, 
    individual_id_counter::Counter,  
    gene_id_counter::Counter,  
    species::AdaptiveArchiveSpecies,
    evaluation::AdaptiveArchiveEvaluation
) 
    new_basic_species = create_species(
        species_creator.basic_species_creator, 
        rng, 
        individual_id_counter, 
        gene_id_counter, 
        species.basic_species, 
        evaluation.full_evaluation
    )
    archive_individual_ids = [individual.id for individual in species.archive]
    n_sample = min(species_creator.n_sample, length(archive_individual_ids))
    weights = [get_size(individual.genotype) for individual in species.archive]
    weights = [weight + 1 for weight in weights]
    active_individual_ids = sample_without_replacement(
        rng, archive_individual_ids, n_sample, weights
    )
    #id_weights = collect(zip(archive_individual_ids, weights))
    #sorted_id_weights = sort(id_weights, by = x -> x[2])
    #ids = [id_weight[1] for id_weight in sorted_id_weights]
    #weights = [id_weight[2] for id_weight in sorted_id_weights]
    # println("--------------$(species.id)------------------")
    # #println("ids: ", ids)
    # #println("weights: ", weights)
    # n_sample = min(species_creator.n_sample, length(archive_individual_ids))
    # active_individuals = [
    #     (individual.id, get_size(individual.genotype) + 1) 
    #     for individual in species.archive 
    #         if individual.id in active_individual_ids
    # ]
    # sort!(active_individuals, by = x -> x[2], rev = false)
    # println("sizes: ", [individual[2] for individual in active_individuals])
    #println("sorted_id_weights: ", sorted_id_weights)
    #active_individual_ids = sample(
    #    rng, archive_individual_ids, n_sample, replace = false
    #)
    species = AdaptiveArchiveSpecies(
        species.id, 
        species.max_archive_size, 
        species.n_sample, 
        new_basic_species, 
        species.archive, 
        active_individual_ids
    )
    return species
end

function get_phenotype_creator(species_creator::AdaptiveArchiveSpeciesCreator)
    phenotype_creator = get_phenotype_creator(species_creator.basic_species_creator)
    return phenotype_creator
end

function get_evaluator(species_creator::AdaptiveArchiveSpeciesCreator)
    evaluator = species_creator.evaluator
    return evaluator
end

end