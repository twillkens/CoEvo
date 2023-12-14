module AdaptiveArchive

export AdaptiveArchiveSpeciesCreator

import ...Individuals: get_individuals
import ...SpeciesCreators: create_species, get_phenotype_creator, get_evaluator

using Random: AbstractRNG
using StatsBase: sample
using DataStructures: OrderedDict
using ...Genotypes: get_size
using ...Counters: Counter
using ...Evaluators: Evaluator, Evaluation
using ...Evaluators.AdaptiveArchive: AdaptiveArchiveEvaluator, AdaptiveArchiveEvaluation
using ...Individuals: Individual
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
    generation::Int = 1
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


# TODO: add to utils
function sample_proportionate_to_genotype_size(
    rng::AbstractRNG, individuals::Vector{<:Individual}, n_sample::Int; 
    inverse::Bool = false,
    replace::Bool = false
)
    complexity_scores = [get_size(individual.genotype) for individual in individuals]
    complexity_scores = 1 .+ complexity_scores
    complexity_scores = inverse ? 1 ./ complexity_scores : complexity_scores
    weights = Weights(complexity_scores)
    return sample(rng, individuals, weights, n_sample, replace = replace)
end

function get_active_individual_ids(rng::AbstractRNG, species::AdaptiveArchiveSpecies)
    archive_individual_ids = [individual.id for individual in species.archive]
    n_sample = min(species.n_sample, length(archive_individual_ids))
    #active_individuals = sample_proportionate_to_genotype_size(
    #    rng, species.archive, n_sample
    #)
    active_individuals = sample(rng, species.archive, n_sample; replace = false)
    active_individual_ids = [individual.id for individual in active_individuals]
    return active_individual_ids
end

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
    if species_creator.generation == 1
        active_individual_ids = Int[]
    elseif species_creator.generation % 50 == 0
        active_individual_ids = get_active_individual_ids(rng, species)
    else
        active_individual_ids = species.active_individual_ids
    end

    #active_individual_ids = species.max_archive_size == 0 ? 
    #    Int[] : get_active_individual_ids(rng, species)
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