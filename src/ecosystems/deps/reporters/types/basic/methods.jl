module Methods

using DataStructures: OrderedDict
using .....Metrics.Abstract: Metric
using .....Metrics.Evaluations.Types: TestBasedFitness
using .....Measurements.Abstract: Measurement
using .....Measurements: BasicStatisticalMeasurement
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using .....Ecosystems.Species.Abstract: AbstractSpecies
using .....Ecosystems.Interactions.Abstract: Interaction
using .....Ecosystems.Interactions.Observers.Abstract: Observation
using  ....Reporters.Abstract: Reporter
using ...Basic: BasicReport, BasicReporter

import ....Reporters.Interfaces: create_report, measure


function Base.show(io::IO, report::BasicReport{TestBasedFitness, BasicStatisticalMeasurement})
    fitness_mean = report.measurement.mean
    fitness_min = report.measurement.minimum
    fitness_max = report.measurement.maximum
    fitness_std = report.measurement.std
    println(io, "Fitness")
    println(io, "Mean: ", fitness_mean)
    println(io, "Min: ", fitness_min)
    println(io, "Max: ", fitness_max)
    println(io, "Std: ", fitness_std)
end

function measure(
    ::Reporter{TestBasedFitness},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    interaction_observations::Dict{<:Interaction, <:Observation}
)
    subject_evaluations = filter(
        (species, evaluation) -> species.id == "subject", collect(species_evaluations)
    )
    evaluation = subject_evaluations[1][2]
    fitnesses = collect(values(evaluation.fitnesses))
    measurement = BasicStatisticalMeasurement(fitnesses)
    return measurement
end

function create_report(
    reporter::BasicReporter,
    to_print::Bool,
    to_save::Bool,
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    interaction_observations::Dict{<:Interaction, <:Observation}
)
    measurement = measure(reporter, species_evaluations, interaction_observations)
    report = BasicReport(
        to_print,
        to_save,
        reporter.metric,
        measurement
    )

    return report
end

function create_report(
    reporter::BasicReporter,
    gen::Int,
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    interaction_observations::Dict{<:Interaction, <:Observation}
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    report = create_report(
        reporter,
        to_print,
        to_save,
        species_evaluations,
        interaction_observations
    )
    return report
end

end