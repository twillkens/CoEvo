"""
    Reports

This module provides functionalities for reporting on cohorts and their associated metrics in 
evolutionary algorithms. The primary struct defined here is `CohortMetricReport`, which captures 
the details and metrics of cohorts for a particular generation.

# Structures
- [`CohortMetricReport`](@ref) : Struct for holding metrics associated with a cohort.

# Methods
- Custom `show` method to display the contents of a `CohortMetricReport` instance.
- Implementation for processing a `CohortMetricReport` through an `Archiver`.
"""
module Reports

export CohortMetricReport

using .....CoEvo.Abstract: Report, Archiver
using .....CoEvo.Utilities.Statistics: StatisticalFeatureSet

"""
    CohortMetricReport <: Report

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
struct CohortMetricReport <: Report
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

# Custom display for CohortMetricReport
function Base.show(io::IO, report::CohortMetricReport)
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

"""
    (archiver::Archiver)(report::CohortMetricReport)

Processes the given `CohortMetricReport` using an `Archiver`. If `to_print` is set to true 
for the report, then the report is displayed.
"""
function(archiver::Archiver)(report::CohortMetricReport)
    if report.to_print
        Base.show(report)
    end
end

end
