module Species

export SpeciesMetric, SnapshotSpeciesMetric, SnapshotSpeciesMeasurement, measure
export StatisticalSpeciesMetric

import ..Metrics: measure, get_name

using ...Species: AbstractSpecies, get_individuals
using ...Evaluators: Evaluation
using ..Metrics: Metric, Measurement
using ..Metrics.Aggregators: Aggregator, aggregate
using ..Metrics.Aggregators: BasicStatisticalAggregator, BasicQuantileAggregator
using ..Metrics.Aggregators: OneSampleTTestAggregator, HigherMomentAggregator
using ..Metrics.Genotypes: GenotypeMetric
using ..Metrics.Evaluations: EvaluationMetric

abstract type SpeciesMetric <: Metric end

struct SnapshotSpeciesMetric <: SpeciesMetric end

struct SnapshotSpeciesMeasurement{S <: AbstractSpecies} <: Measurement
    species::S
end

function measure(::SnapshotSpeciesMetric, all_species::Vector{<:AbstractSpecies})
    measurements = [SnapshotSpeciesMeasurement(species) for species in all_species]
    return measurements
end

Base.@kwdef struct StatisticalSpeciesMetric{M <: Metric, A <: Aggregator} <: SpeciesMetric
    submetric::M
    name::String = "species"
    cohorts::Vector{String} = ["population"]
    aggregators::Vector{A} = [
        BasicStatisticalAggregator(),
        BasicQuantileAggregator(),
        OneSampleTTestAggregator(),
        HigherMomentAggregator()
    ]
    species_to_print::Union{String, Vector{String}} = "all"
    species_to_save::Union{String, Vector{String}} = "all"
    measurements_to_print::Union{String, Vector{String}} = ["mean", "maximum", "minimum", "std"]
    measurements_to_save::Union{String, Vector{String}} = "all"
end

function measure(metric::SpeciesMetric, all_species::Vector{<:AbstractSpecies})
    measurements = vcat([measure(metric, species) for species in all_species]...)
    return measurements
end

function measure(metric::SpeciesMetric, evaluations::Vector{<:Evaluation})
    measurements = vcat([measure(metric, evaluation) for evaluation in evaluations]...)
    return measurements
end

function aggregate_measurements(
    aggregators::Vector{<:Aggregator}, 
    metric::Metric, 
    base_path::String, 
    measurements::Vector{<:Measurement}
)
    aggregated_measurements = vcat([
        aggregate(aggregator, metric, base_path, measurements) for aggregator in aggregators
    ]...)
    return aggregated_measurements
end

function measure(metric::StatisticalSpeciesMetric{<:GenotypeMetric}, species::AbstractSpecies)
    individuals = get_individuals(species, metric.cohorts)
    genotypes = [individual.genotype for individual in individuals]
    measurements = [measure(metric.submetric, genotype) for genotype in genotypes]
    submetric_name = get_name(metric.submetric)
    base_path = "species/$(species.id)/$submetric_name)"
    measurements = aggregate_measurements(metric.aggregators, metric, base_path, measurements)
    return measurements
end

function measure(metric::StatisticalSpeciesMetric{<:EvaluationMetric}, evaluation::Evaluation)
    measurements = measure(metric.submetric, evaluation)
    submetric_name = get_name(metric.submetric)
    base_path = "species/$(evaluation.id)/$submetric_name)"
    measurements = aggregate_measurements(metric.aggregators, metric, base_path, measurements)
    return measurements
end

end