export create_report

import ...Reporters: create_report

using Random: AbstractRNG
using StatsBase: sample
using ...Species: get_all_ids, AbstractSpecies
using ...Species.Basic: BasicSpecies
using ...Species.AdaptiveArchive: AdaptiveArchiveSpecies, add_individuals_to_archive!
using ...SpeciesCreators: SpeciesCreator
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...SpeciesCreators.AdaptiveArchive: AdaptiveArchiveSpeciesCreator
using ...Jobs: JobCreator
using ...Performers: Performer
using ...Performers.Modes: perform_modes
using ...Reporters.Basic: NullReport, BasicReport
using ...States: State

function create_report(
    reporter::ModesReporter,
    trial::Int,
    generation::Int, 
    species_creators::Vector{<:BasicSpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:BasicSpecies};
    include_pruned_individuals_dict::Bool = false
)
    if generation == 1
        update_species_list!(reporter, all_species)
        reset_tag_dictionary!(reporter)
        update_tag_dictionary!(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
        reporter.previous_modes_generation = generation
    elseif generation % reporter.modes_interval == 0
        pruned_individuals_dict = perform_modes(
            performer,
            species_creators, 
            job_creator,
            random_number_generator,
            reporter.all_species,
            reporter.persistent_ids
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
        update_species_list!(reporter, all_species)
        reset_tag_dictionary!(reporter)
        update_tag_dictionary!(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
        reporter.previous_modes_generation = generation
        report = BasicReport(
            reporter.metric, 
            measurements, 
            trial, 
            generation, 
            reporter.to_print, 
            reporter.to_save
        )
        return report
    else
        update_persistent_ids!(reporter, all_species)
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
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AdaptiveArchiveSpecies}
)
    basic_species = [species.basic_species for species in all_species]
    basic_species_creators = [
        species_creator.basic_species_creator for species_creator in species_creators
    ]
    report = create_report(
        reporter,
        trial,
        generation,
        basic_species_creators,
        job_creator,
        performer,
        random_number_generator,
        basic_species;
        include_pruned_individuals_dict = true
    )
    if isa(report, NullReport)
        return report
    end
    pruned_individuals_dict = first(filter(
        measurement -> measurement.name == "pruned_individuals_dict", report.measurements)
    ).value
    filter!(measurement -> measurement.name != "pruned_individuals_dict", report.measurements)
    for species in all_species
        new_individuals = pruned_individuals_dict[species.id]
        add_individuals_to_archive!(random_number_generator, species, new_individuals)
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
        state.species
    )
    return report
end