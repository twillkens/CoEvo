export BasicSpeciesReporter

using DataStructures: OrderedDict

using .....Ecosystems.Utilities.Statistics: StatisticalFeatureSet
using ..Abstract: Individual, SpeciesReport, SpeciesReporter
using ..Metrics.Abstract: Metric, EvaluationMetric, GenotypeMetric

import ..Interfaces: create_report

"""
    BasicSpeciesReport <: Report

A report structure to capture details and metrics associated with a cohort 
in a particular generation of an evolutionary algorithm.

# Fields
- `gen::Int`: The generation number.
- `to_print::Bool`: Whether the report should be printed or not.
- `to_save::Bool`: Whether the report should be saved or not.
- `species_id::String`: ID of the species.
- `cohort::String`: Name/ID of the cohort.
- `metric::String`: Metric being reported.
- `stat_features::StatisticalFeatureSet`: Statistical features associated with the cohort.
- `print_features::Vector{Symbol}`: Features to be printed.
- `save_features::Vector{Symbol}`: Features to be saved.
"""
struct BasicSpeciesReport{MET <: Metric, MEA <: MeasurementSet} <: SpeciesReport{M}
    gen::Int
    to_print::Bool
    to_save::Bool
    species_id::String
    cohort::Strine
    metric::MET
    measure_set::MEA
    print_measures::Vector{Symbol}
    save_measures::Vector{Symbol}
end

# Custom display for BasicSpeciesReport
function Base.show(io::IO, report::BasicSpeciesReport)
    println(io, "----------------------SPECIES-------------------------------")
    println(io, "Generation $(report.gen)")
    println(io, "Species ID: $(report.species_id)")
    println(io, "Cohort: $(report.cohort)")
    println(io, "Metric: $(report.metric)")
    
    for measurement in report.print_measures
        value = getfield(report.measurement_set, measurement)
        println(io, "    $measurement: $value")
    end
end

Base.@kwdef struct BasicSpeciesReporter{M <: Metric} <: SpeciesReporter{M}
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 2
    to_check::Vector{Pair{String, String}} = Vector{Pair{String, String}}[]
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end

"""
    function(reporter::BasicSpeciesReporter)(
        gen::Int,
        species_id::String,
        cohort::String,
        values::Vector{Float64}
    )

Generate a report based on provided cohort metrics for a specified generation, species, and cohort.

# Arguments
- `gen::Int`: Generation number.
- `species_id::String`: ID of the species.
- `cohort::String`: Name/ID of the cohort.
- `values::Vector{Float64}`: Vector of values (either evaluations or genotypes) from which the statistical features are derived.

# Returns
- A `BasicSpeciesReport` instance containing the generated report details.
"""
function create_reports(
    reporter::BasicSpeciesReporter{<:SpeciesMetric},
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    ::Vector{Observation},
    species_evalutions::Dict{String, Dict{String, Dict{<:Individual, <:Evaluation}}}
)
    reports = Report[]
    if length(reporter.to_check) > 0
        species_evalutions = filter_species_evaluations(species_evalutions, reporter.to_check)
    end
    for (species_id, cohort_id_indiv_evals) in species_id_evalutions
        for (cohort_id, indiv_evals) in cohort_id_indiv_evals
            measure_set = measure(reporter, indiv_evals)
            report = BasicSpeciesReport(
                gen,
                to_print,
                to_save,
                species_id,
                cohort_id,
                reporter.metric,
                measure_set,
                reporter.print_measures,
                reporter.save_measures
            )
            push!(reports, report)
        end
    end

    return reports
end

