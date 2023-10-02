module Basic

export BasicReporter

using DataStructures: OrderedDict
using ...Reporters.Abstract: Reporter, Report
using ...Metrics.Abstract: Metric
using ...Metrics.Species.Types: FitnessMetric
using ...Measures.Abstract: MeasureSet
using ...Measures: BasicStatisticalMeasureSet
using ....Ecosystems.Species.Evaluators.Types: ScalarFitnessEvaluation
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation
using ....Ecosystems.Species.Abstract: AbstractSpecies
using ....Ecosystems.Interactions.Observers.Abstract: Observation

import ..Interfaces: create_reports

struct BasicReport{MET <: Metric, MEA <: MeasureSet} <: Report{MET, MEA}
    gen::Int
    to_print::Bool
    to_save::Bool
    species_id::String
    metric::MET
    measure_set::MEA
    print_measures::Vector{Symbol}
    save_measures::Vector{Symbol}
end

# Custom display for BasicSpeciesReport
function Base.show(io::IO, report::BasicReport)
    println(io, "----------------------SPECIES-------------------------------")
    println(io, "Generation $(report.gen)")
    println(io, "Species ID: $(report.species_id)")
    println(io, "Metric: $(report.metric)")
    
    for measurement in report.print_measures
        value = getfield(report.measure_set, measurement)
        println(io, "    $measurement: $value")
    end
end

Base.@kwdef struct BasicReporter{M <: Metric} <: Reporter{M}
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 3
    print_measures::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_measures::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end


function measure(
    ::BasicReporter{FitnessMetric},
    ::AbstractSpecies,
    evaluation::ScalarFitnessEvaluation,
    ::Vector{Observation},
)
    fitnesses = collect(values(evaluation.fitnesses))
    measure_set = BasicStatisticalMeasureSet(fitnesses)
    return measure_set
end

function create_reports(
    reporter::BasicReporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    all_species::Dict{String, <:AbstractSpecies},
    all_evaluations::Dict{String, <:Evaluation},
    all_observations::Vector{<:Observation},
)
    reports = Report[]
    for (species_id, species) in all_species
        evaluation = all_evaluations[species_id]
        measure_set = measure(reporter, species, evaluation, all_observations)
        report = BasicReport(
            gen,
            to_print,
            to_save,
            species_id,
            reporter.metric,
            measure_set,
            reporter.print_measures,
            reporter.save_measures
        )
        push!(reports, report)
    end

    return reports
end
end