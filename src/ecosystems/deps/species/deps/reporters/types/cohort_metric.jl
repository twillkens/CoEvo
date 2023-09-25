export CohortMetricReporter

using DataStructures: OrderedDict
using ....CoEvo.Abstract: Reporter, EvaluationMetric, GenotypeMetric, Individual, Evaluation
using ....CoEvo.Abstract: Metric
using ....CoEvo.Utilities.Statistics: StatisticalFeatureSet
using .Reports: CohortMetricReport

Base.@kwdef struct CohortMetricReporter{M <: Metric} <: Reporter
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 2
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end

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

function(reporter::CohortMetricReporter{<:EvaluationMetric})(
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    report = reporter(gen, species_id, cohort, collect(values(indiv_evals)))
    return report
end

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
