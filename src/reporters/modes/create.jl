export create_report

import ...Reporters: create_report
import ...Metrics: measure

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
using ...Individuals.Modes: ModesIndividual
using ...Evaluators: Evaluation
using ...Evaluators.AdaptiveArchive: get_elite_records

function set_persistent_ids!(reporter::ModesReporter, all_species::Vector{<:BasicSpecies})
    empty!(reporter.persistent_ids)
    for id in get_all_ids(all_species)
        push!(reporter.persistent_ids, id)
    end
end

function initialize_checkpoint!(reporter::ModesReporter, all_species::Vector{<:BasicSpecies})
    update_species_list!(reporter, all_species)
    reset_tag_dictionary!(reporter)
    update_tag_dictionary!(reporter, all_species)
    set_persistent_ids!(reporter, all_species)
end

function measure(
    reporter::ModesReporter, 
    pruned_individuals_dict::Dict{String, Vector{ModesIndividual}},
    include_pruned_individuals_dict::Bool = false
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
    if include_pruned_individuals_dict
        pruned_individuals_dict_measurement = BasicMeasurement(
            "pruned_individuals_dict", pruned_individuals_dict
        )
        push!(measurements, pruned_individuals_dict_measurement)
    end
end

function create_report(
    reporter::ModesReporter,
    trial::Int,
    generation::Int, 
    species_creators::Vector{<:BasicSpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:BasicSpecies};
    include_pruned_individuals::Bool = false
)
    if generation == 1
        initialize_checkpoint!(reporter, all_species)
    elseif generation % reporter.modes_interval == 0
        pruned_individuals_dict = perform_modes(
            performer,
            species_creators, 
            job_creator,
            random_number_generator,
            reporter.all_species,
            reporter.persistent_ids
        )
        measurements = measure(reporter, pruned_individuals_dict, include_pruned_individuals)
        initialize_checkpoint!(reporter, all_species)
        metric = reporter.metric
        report = BasicReport(
            metric, measurements, trial, generation, reporter.to_print, reporter.to_save
        )
        return report
    else
        update_persistent_ids!(reporter, all_species)
    end
    return NullReport() 
end

using ...Evaluators: get_elite_ids
using ...Species.AdaptiveArchive: add_modes_elite_to_archive! 

function create_report(
    reporter::ModesReporter,
    trial::Int,
    generation::Int,
    species_creators::Vector{<:AdaptiveArchiveSpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AdaptiveArchiveSpecies},
    evaluations::Vector{<:Evaluation}
)
    all_basic_species = [species.basic_species for species in all_species]
    basic_species_creators = [
        species_creator.basic_species_creator for species_creator in species_creators
    ]
    report = create_report(
        reporter, trial, generation, basic_species_creators, job_creator, performer,
        random_number_generator, all_basic_species;
        include_pruned_individuals = true
    )
    if isa(report, NullReport)
        for (species, basic_species, evaluation) in zip(all_species, all_basic_species, evaluations)
            elite_records = get_elite_records(evaluation, 1)
            elite_ids = [record.id for record in elite_records]
            elite_individuals = get_individuals(basic_species, elite_ids)
            elite_fitnesses = [record.scaled_fitness for record in elite_records]
            add_elites!(species, elite_individuals, elite_fitnesses)
        end
        return report
    end
    pruned_individuals_dict = first(filter(
        measurement -> measurement.name == "pruned_individuals_dict", report.measurements)
    ).value
    filter!(measurement -> measurement.name != "pruned_individuals_dict", report.measurements)
    for (species, basic_species, evaluation) in zip(all_species, all_basic_species, evaluations)
        new_individuals = pruned_individuals_dict[species.id]
        add_modes_elite_to_archive!(random_number_generator, species, new_individuals)
        elite_records = get_elite_records(evaluation, 1)
        elite_ids = [record.id for record in elite_records]
        elite_individuals = get_individuals(basic_species, elite_ids)
        elite_fitnesses = [record.scaled_fitness for record in elite_records]
        add_elites!(species, elite_individuals, elite_fitnesses)
    end
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
        state.random_number_generator,
        state.species,
        state.evaluations
    )
    return report
end
