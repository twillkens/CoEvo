module AdaptiveArchive

export AdaptiveArchiveSpeciesCreator

import ...Individuals: get_individuals
import ...SpeciesCreators: create_species, get_phenotype_creator, get_evaluator

using Random: AbstractRNG
using StatsBase: sample
using DataStructures: OrderedDict
using Random, Distributions
using StatsBase: sample, Weights
using ...Genotypes: get_size
using ...Counters: Counter, count!
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
    generation::Ref{Int} = Ref(1)
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
        id = species_creator.id, 
        max_archive_size = species_creator.max_archive_size, 
        basic_species = basic_species, 
        archive = I[], 
        n_sample = 0, #species_creator.n_sample,
        active_ids = Int[],
        elites = I[], 
        n_sample_elites = species_creator.n_sample,
        active_elite_ids = Int[],
        fitnesses = Dict{Int, Float64}(),
        modes_elites = I[]
    )
    return species
end

using ...Individuals.Basic: BasicIndividual 
using ...Evaluators: get_records

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
    #println(new_basic_species)
    active_adaptive_ids = Int[]
    
    if species_creator.generation == 1 || length(species.elites) == 0
        active_elite_ids = Int[]
    else 
        # TODO: gross hack
        if length(species.elites) <= 50
            active_elite_ids = [individual.id for individual in species.elites]
        else
            active_elite_ids = copy(species.active_elite_ids)
            old_index = sample(rng, 1:length(active_elite_ids))
            old_elite_id = Set([active_elite_ids[old_index]])
            invalid_ids = union(Set([individual.id for individual in species.elites]), old_elite_id)
            all_elite_ids = Set([individual.id for individual in species.elites])
            valid_elite_ids = collect(setdiff(all_elite_ids, invalid_ids))
            if length(valid_elite_ids) != 0
                new_elite_id = sample(rng, valid_elite_ids)
                active_elite_ids[old_index] = new_elite_id
            end

        end
    end
    if length(Set(active_elite_ids)) != length(active_elite_ids)
        throw(ErrorException("active_elite_ids contains duplicates"))
    end
    species_creator.generation[] += 1

    species = AdaptiveArchiveSpecies(
        species.id, 
        species.max_archive_size, 
        new_basic_species, 
        species.archive, 
        species.n_sample, 
        active_adaptive_ids,
        species.elites,
        species.n_sample_elites,
        active_elite_ids,
        species.fitnesses,
        species.modes_elites
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
# function get_active_individual_ids(rng::AbstractRNG, species::AdaptiveArchiveSpecies)
#     archive_individual_ids = [individual.id for individual in species.archive]
#     n_sample = min(species.n_sample, length(archive_individual_ids))
#     #active_individuals = sample_proportionate_to_genotype_size(
#     #    rng, species.archive, n_sample
#     #)
#     active_individuals = sample(rng, species.archive, n_sample; replace = false)
#     active_individual_ids = [individual.id for individual in active_individuals]
#     return active_individual_ids
# end