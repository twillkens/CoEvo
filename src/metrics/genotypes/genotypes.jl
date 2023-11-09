module Genotypes

export GenotypeMetric, SizeGenotypeMetric, SumGenotypeMetric

using ...Genotypes: Genotype, get_size, minimize
using ...Individuals: Individual
using ..Metrics: Metric, Aggregator, get_name, aggregate
using ..Metrics.Aggregators: BasicFeatureAggregator, BasicQuantileAggregator
using ..Metrics.Aggregators: OneSampleTTestAggregator, HigherMomentAggregator
using ..Metrics.Common: BasicMeasurement, BasicGroupMeasurement
using ..Metrics.Individuals: IndividualMetric

abstract type GenotypeMetric <: IndividualMetric end

function measure(metric::GenotypeMetric, individual::Individual)
    measurement = measure(metric, individual.genotype)
    return measurement
end

function measure(metric::GenotypeMetric, individuals::Vector{<:Individual})
    genotypes = [individual.genotype for individual in individuals]
    measurements = measure(metric, genotypes)
    return measurements
end

function measure(metric::GenotypeMetric, genotypes::Vector{<:Genotype})
    measurements = [measure(metric, genotype) for genotype in genotypes]
    return measurements
end

Base.@kwdef struct SizeGenotypeMetric{A <: Aggregator} <: GenotypeMetric 
    name::String = "GenotypeSize"
    cohorts::Vector{String} = ["population"]
    perform_minimization::Bool = false
    aggregators::Vector{A} = [
        BasicFeatureAggregator(),
        BasicQuantileAggregator(),
        OneSampleTTestAggregator(),
        HigherMomentAggregator()
    ]
end

function get_name(metric::SizeGenotypeMetric)
    name = metric.perform_minimization ? "MinimizedGenotypeSize" : "GenotypeSize"
    return name
end

function measure(metric::SizeGenotypeMetric, genotype::Genotype)
    size = metric.perform_minimization ? minimize(genotype) : get_size(genotype)
    measurement = BasicMeasurement(metric, size)
    return measurement
end

Base.@kwdef struct SumGenotypeMetric{A <: Aggregator} <: Metric 
    name::String = "GenotypeSum"
    cohorts::Vector{String} = ["population"]
    aggregators::Vector{A} = [
        BasicFeatureAggregator(),
        BasicQuantileAggregator(),
        OneSampleTTestAggregator(),
        HigherMomentAggregator()
    ]
end

function measure(metric::SumGenotypeMetric, genotype::Genotype)
    genotype_sum = sum(genotype)
    measurement = BasicMeasurement(metric, genotype_sum)
    return measurement
end

end