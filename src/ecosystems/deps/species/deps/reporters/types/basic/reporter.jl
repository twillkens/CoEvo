export BasicSpeciesReporter

using DataStructures: OrderedDict

using ....Ecosystems.Utilities.Statistics: StatisticalFeatureSet
using ...Species.Individuals.Abstract: Individual
using .Abstract: SpeciesReport, SpeciesReporter, create_report
using .Metrics.Abstract: Metric, EvaluationMetric, GenotypeMetric

import .Abstract: create_report

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
struct BasicSpeciesReport <: SpeciesReport
    gen::Int
    to_print::Bool
    to_save::Bool
    species_id::String
    cohort::String
    metric::String
    stat_features::StatisticalFeatureSet
    print_features::Vector{Symbol}
    save_features::Vector{Symbol}
end

# Custom display for BasicSpeciesReport
function Base.show(io::IO, report::BasicSpeciesReport)
    println(io, "-----------------------------------------------------------")
    println(io, "Generation $(report.gen)")
    println(io, "Species ID: $(report.species_id)")
    println(io, "Cohort: $(report.cohort)")
    println(io, "Metric: $(report.metric)")
    
    for feature in report.print_features
        val = getfield(report.stat_features, feature)
        println(io, "    $feature: $val")
    end
end

Base.@kwdef struct BasicSpeciesReporter{M <: Metric} <: SpeciesReporter
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 2
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
function create_report(
    reporter::BasicSpeciesReporter,
    gen::Int,
    species_id::String,
    cohort::String,
    values::Vector{Float64}
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    stat_features = StatisticalFeatureSet(values, reporter.n_round)
    report = BasicSpeciesReport(
        gen,
        to_print,
        to_save,
        species_id, 
        cohort, 
        reporter.metric.name,
        stat_features,
        reporter.print_features,
        reporter.save_features
    )
    return report
end

