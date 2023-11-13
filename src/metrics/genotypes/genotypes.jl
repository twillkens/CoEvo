module Genotypes

export GenotypeMetric, SizeGenotypeMetric, SumGenotypeMetric

import ..Metrics: get_name, measure

using ...Genotypes: Genotype, get_size, minimize
using ...Individuals: Individual
using ..Metrics: Metric
using ..Metrics.Common: BasicMeasurement

abstract type GenotypeMetric <: Metric end

function measure(metric::GenotypeMetric, individual::Individual)
    measurement = measure(metric, individual.genotype)
    measurement = BasicMeasurement(string(individual.id), measurement.value)
    return measurement
end

function measure(metric::GenotypeMetric, individuals::Vector{<:Individual})
    measurements = [measure(metric, individual) for individual in individuals]
    return measurements
end

function measure(metric::GenotypeMetric, genotypes::Vector{<:Genotype})
    measurements = [measure(metric, genotype) for genotype in genotypes]
    return measurements
end

Base.@kwdef struct SizeGenotypeMetric <: GenotypeMetric 
    perform_minimization::Bool = false
end

function get_name(metric::SizeGenotypeMetric)
    name = metric.perform_minimization ? "minimized_genotype_size" : "genotype_size"
    return name
end

function measure(metric::SizeGenotypeMetric, genotype::Genotype)
    name = get_name(metric)
    size = metric.perform_minimization ? minimize(genotype) : get_size(genotype)
    measurement = BasicMeasurement(name, size)
    return measurement
end

Base.@kwdef struct SumGenotypeMetric <: Metric 
    name::String = "genotype_sum"
end

function measure(metric::SumGenotypeMetric, genotype::Genotype)
    name = get_name(metric)
    genotype_sum = sum(genotype)
    measurement = BasicMeasurement(name, genotype_sum)
    return measurement
end

end