export create_report

import ...Reporters: create_report
import ...Metrics: measure
import ...Species.AdaptiveArchive: add_modes_elite_to_archive! 


using Random: AbstractRNG
using StatsBase: sample
using ...Species: get_all_ids, AbstractSpecies
using ...Species.Basic: BasicSpecies
using ...Species.AdaptiveArchive: AdaptiveArchiveSpecies, add_individuals_to_archive!, add_elites!
using ...SpeciesCreators: SpeciesCreator
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...SpeciesCreators.AdaptiveArchive: AdaptiveArchiveSpeciesCreator
using ...Jobs: JobCreator
using ...Performers: Performer
using ...Performers.Modes: perform_modes
using ...Reporters.Basic: NullReport, BasicReport
using ...States: State
using ...Individuals.Modes: PruneIndividual
using ...Evaluators: Evaluation
using ...Evaluators.AdaptiveArchive: get_elite_records
using ...Evaluators: get_elite_ids
using ...Counters: Counter, count!

function measure(
    reporter::ModesReporter, 
    pruned_individuals_dict::Dict{String, Vector{PruneIndividual}},
)
    pruned_individuals = vcat(values(pruned_individuals_dict)...)
    pruned_genotypes = [individual.genotype for individual in pruned_individuals]
    modes_complexity = measure(reporter.complexity_metric, pruned_genotypes)
    novelty = calculate_novelty!(reporter, pruned_genotypes)
    change = calculate_change!(reporter, pruned_genotypes)
    genotype_measurements = [
        BasicMeasurement("modes/individuals/$(individual.id)/genotype", individual.genotype)
        for individual in pruned_individuals
    ]
    measurements = [
        BasicMeasurement("modes/change", change),
        BasicMeasurement("modes/novelty", novelty.value),
        BasicMeasurement("modes/complexity", modes_complexity.value),
        genotype_measurements...
    ]
    return measurements
end

function add_normal_elites!(all_species, all_basic_species, evaluations)
    for (species, basic_species, evaluation) in zip(all_species, all_basic_species, evaluations)
        elite_records = get_elite_records(evaluation, 1)
        elite_ids = [record.id for record in elite_records]
        elite_individuals = get_individuals(basic_species, elite_ids)
        elite_fitnesses = [record.scaled_fitness for record in elite_records]
        add_elites!(species, elite_individuals, elite_fitnesses)
    end
end

function create_report(reporter, trial, generation, pruned_individuals_dict)
    measurements = measure(reporter, pruned_individuals_dict)
    metric = reporter.metric
    report = BasicReport(
        metric, measurements, trial, generation, reporter.to_print, reporter.to_save
    )
    return report
end

function add_modes_elite_to_archive!(rng, all_species, pruned_individuals_dict)
    for species in all_species
        new_individuals = pruned_individuals_dict[species.id]
        println("LENGTH NEW INDIVIDUALS: $(length(new_individuals))")
        add_modes_elite_to_archive!(rng, species, new_individuals)
    end
end
using ...Individuals.Basic: BasicIndividual
using ...Evaluators: get_records

function add_modes_elite_to_species!(
    species::AdaptiveArchiveSpecies, 
    individual_id_counter::Counter, 
    evaluation::Evaluation
)
    if length(species.modes_elites) > 0
        println("MOOOOODES FOR $(species.id)")
        population_length_before = length(species.basic_species.population)
        n_replace_with_modes_elites = minimum([25, length(species.modes_elites)])
        population_ids = [individual.id for individual in species.basic_species.population]
        fitnessess = [
            record.fitness for record in get_records(evaluation.full_evaluation, population_ids)
        ]
        id_fitnessess = collect(zip(population_ids, fitnessess))
        sort!(id_fitnessess, by = x -> x[2])
        worst_individual_ids = Set(
            [id_fitness[1] for id_fitness in id_fitnessess[1:n_replace_with_modes_elites]]
        )
        filter!(individual -> individual.id ∉ worst_individual_ids, species.basic_species.population)
        modes_elites = collect(reverse(species.modes_elites))[1:n_replace_with_modes_elites]
        individual_ids = count!(individual_id_counter, n_replace_with_modes_elites)
        modes_elites = [
            BasicIndividual(-individual_id, modes_elite.genotype, [modes_elite.id])
            for (individual_id, modes_elite) in zip(individual_ids, modes_elites)
        ]
        println("elite ids before: $([individual.id for individual in species.modes_elites])")
        for i in eachindex(modes_elites)
            modes_elites = collect(reverse(modes_elites))
            species.modes_elites[end - i + 1] = modes_elites[i]
        end
        println("FINAL ELITE IDS: $([individual.id for individual in modes_elites])")
        append!(species.basic_species.population, modes_elites)
        population_length_after = length(species.basic_species.population)
        if population_length_before != population_length_after
            throw(ErrorException("population length changed"))
        end
        println("Population ids: $([individual.id for individual in species.basic_species.population])")
        println("Children ids: $([individual.id for individual in species.basic_species.children])")
    else
        println("NO MOOOOODES FOR $(species.id)")
    end
end

using ...Counters: Counter

function add_modes_elite_to_species!(
    all_species::Vector{<:AdaptiveArchiveSpecies}, 
    individual_id_counter::Counter,
    evaluations::Vector{<:Evaluation}
)
    for (species, evaluation) in zip(all_species, evaluations)
        add_modes_elite_to_species!(species, individual_id_counter, evaluation)
    end
end

function create_report(
    reporter::ModesReporter,
    trial::Int,
    generation::Int, 
    species_creators::Vector{<:BasicSpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    rng::AbstractRNG,
    all_adaptive_species::Vector{<:AdaptiveArchiveSpecies},
    all_basic_species::Vector{<:BasicSpecies},
    evaluations::Vector{<:Evaluation},
    individual_id_counter::Counter
)
    if generation == 1
        #println("REPORTER TAGS BEFORE CHECKPOINT: $(reporter.tag_dictionary)")
        initialize_checkpoint!(reporter, all_basic_species)
        #println("REPORTER TAGS AFTER CHECKPOINT: $(reporter.tag_dictionary)")
    elseif generation % reporter.modes_interval == 0
        add_normal_elites!(all_adaptive_species, all_basic_species, evaluations)
        pruned_individuals_dict = perform_modes(
            performer, species_creators, job_creator,
            rng, reporter.all_species, reporter.persistent_ids
        )
        add_modes_elite_to_archive!(rng, all_adaptive_species, pruned_individuals_dict)
        report = create_report(reporter, trial, generation, pruned_individuals_dict)
        return report
    elseif generation > 50 && generation + 1 % reporter.modes_interval == 0
        add_modes_elite_to_species!(all_adaptive_species, individual_id_counter, evaluations)
        initialize_checkpoint!(reporter, all_basic_species)
    else
        add_normal_elites!(all_adaptive_species, all_basic_species, evaluations)
        println("REPORTER TAGS BEFORE UPDATE: $(reporter.tag_dictionary)")
        update_persistent_ids!(reporter, all_basic_species)
        println("REPORTER TAGS AFTER CHECKPOINT: $(reporter.tag_dictionary)")
    end
    return NullReport() 
end

function create_report(
    reporter::ModesReporter,
    trial::Int,
    generation::Int,
    species_creators::Vector{<:AdaptiveArchiveSpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    rng::AbstractRNG,
    all_species::Vector{<:AdaptiveArchiveSpecies},
    evaluations::Vector{<:Evaluation},
    individual_id_counter::Counter
)
    all_basic_species = [species.basic_species for species in all_species]
    basic_species_creators = [
        species_creator.basic_species_creator for species_creator in species_creators
    ]
    report = create_report(
        reporter, trial, generation, basic_species_creators, job_creator, performer,
        rng, all_species, all_basic_species, evaluations,
        individual_id_counter
    )
    return report
end

function create_report(reporter::ModesReporter, state::State)
    report = create_report(
        reporter, 
        state.trial,
        state.generation, 
        state.species_creators,
        state.job_creator,
        state.performer,
        state.rng,
        state.species,
        state.evaluations,
        state.individual_id_counter
    )
    return report
end
