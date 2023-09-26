export CohortMetricReporter

using DataStructures: OrderedDict
using ....CoEvo.Abstract: Reporter, EvaluationMetric, GenotypeMetric, Individual, Evaluation
using ....CoEvo.Abstract: Metric
using ....CoEvo.Utilities.Statistics: StatisticalFeatureSet
using .Reports: CohortMetricReport

"""
    CohortMetricReporter{M <: Metric} <: Reporter

Structure to handle reporting of metrics specific to cohorts of individuals.

# Fields
- `metric::M`: The metric to be reported.
- `print_interval::Int`: Interval at which reports should be printed. 0 means no printing.
- `save_interval::Int`: Interval at which reports should be saved. 0 means no saving.
- `n_round::Int`: Precision for rounding statistical values.
- `print_features::Vector{Symbol}`: Statistical features to print.
- `save_features::Vector{Symbol}`: Statistical features to save.

# Usage
This reporter can handle different types of metrics and produce reports accordingly.
"""
Base.@kwdef struct CohortMetricReporter{M <: Metric} <: Reporter
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 2
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end

"""
    function(reporter::CohortMetricReporter)(
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
- A `CohortMetricReport` instance containing the generated report details.
"""
function(reporter::CohortMetricReporter)(
    gen::Int,
    species_id::String,
    cohort::String,
    values::Vector{Float64}
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    stat_features = StatisticalFeatureSet(values, reporter.n_round)
    report = CohortMetricReport(
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

"""
    function(reporter::CohortMetricReporter{<:EvaluationMetric})(
        gen::Int,
        species_id::String,
        cohort::String,
        indiv_evals::OrderedDict{<:Individual, <:Evaluation}
    )

Specialized function to generate a report when the metric is of type `EvaluationMetric`.

# Arguments
- `gen::Int`: Generation number.
- `species_id::String`: ID of the species.
- `cohort::String`: Name/ID of the cohort.
- `indiv_evals::OrderedDict{<:Individual, <:Evaluation}`: Ordered dictionary of individuals and their evaluations.

# Returns
- A `CohortMetricReport` instance containing the generated report details.
"""
function(reporter::CohortMetricReporter{<:EvaluationMetric})(
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    report = reporter(gen, species_id, cohort, collect(values(indiv_evals)))
    return report
end

"""
    function(reporter::CohortMetricReporter{<:GenotypeMetric})(
        gen::Int,
        species_id::String,
        cohort::String,
        indiv_evals::OrderedDict{<:Individual, <:Evaluation}
    )

Specialized function to generate a report when the metric is of type `GenotypeMetric`.

# Arguments
- `gen::Int`: Generation number.
- `species_id::String`: ID of the species.
- `cohort::String`: Name/ID of the cohort.
- `indiv_evals::OrderedDict{<:Individual, <:Evaluation}`: Ordered dictionary of individuals and their evaluations.

# Returns
- A `CohortMetricReport` instance containing the generated report details.
"""
function(reporter::CohortMetricReporter{<:GenotypeMetric})(
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    report = reporter(gen, species_id, cohort, genotypes)
    return report
end

