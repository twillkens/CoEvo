export create_report

using Random: AbstractRNG
using ...Species: get_all_ids, AbstractSpecies
using ...SpeciesCreators: SpeciesCreator
using ...Jobs: JobCreator
using ...Performers: Performer
using ...Performers.Modes: perform_modes
using ...Reporters.Basic: NullReport, BasicReport
using ...States: State

function create_report(
    reporter::ModesReporter,
    trial::Int,
    generation::Int, 
    species_creators::Vector{<:SpeciesCreator},
    job_creator::JobCreator,
    performer::Performer,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AbstractSpecies}
)
    if generation == 1
        update_species_list!(reporter, all_species)
        reset_tag_dictionary!(reporter)
        update_tag_dictionary!(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
        reporter.previous_modes_generation = generation
    elseif generation % reporter.modes_interval == 0
        pruned_individuals = perform_modes(
            species_creators, 
            job_creator,
            performer,
            random_number_generator,
            reporter.all_species,
            reporter.persistent_ids
        )
        pruned_genotypes = [individual.genotype for individual in pruned_individuals]
        modes_complexity = measure(reporter.complexity_metric, pruned_genotypes)
        #species_complexity = get_maximum_complexity(reporter.all_species)
        novelty = calculate_novelty!(reporter, pruned_individuals)
        change = calculate_change!(reporter, pruned_individuals)
        #quick_print(generation, modes_complexity, species_complexity, novelty, change)
        genotype_measurements = [
            BasicMeasurement("modes/individuals/$(individual.id)/genotype", individual.genotype)
            for individual in pruned_individuals
        ]
        measurements = [
            BasicMeasurement("modes/change", change),
            BasicMeasurement("modes/novelty", novelty),
            BasicMeasurement("modes/complexity", modes_complexity),
            genotype_measurements...
        ]
        update_species_list!(reporter, all_species)
        reset_tag_dictionary!(reporter)
        update_tag_dictionary!(reporter, all_species)
        reporter.persistent_ids = get_all_ids(all_species)
        reporter.previous_modes_generation = generation
        report = BasicReport(reporter.metric, measurements, trial, generation, true, true)
        return report
    else
        update_persistent_ids!(reporter, all_species)
    end
    return NullReport() 
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