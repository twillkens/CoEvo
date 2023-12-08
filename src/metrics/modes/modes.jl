module Modes

export MaximumComplexityMetric, ModesNoveltyMetric, ModesChangeMetric, ModesMetric

import ...Metrics: measure

using Base: @kwdef
using ...Genotypes: Genotype, get_size
using ...Metrics: Metric, Measurement
using ...Metrics.Common: BasicMeasurement

@kwdef struct MaximumComplexityMetric <: Metric
    name::String = "complexity"
end

function measure(metric::MaximumComplexityMetric, genotypes::Vector{<:Genotype})
    maximum_complexity = maximum([get_size(genotype) for genotype in genotypes])
    measurement = BasicMeasurement(metric, maximum_complexity)
    return measurement
end

@kwdef struct ModesNoveltyMetric <: Metric
    name::String = "novelty"
end

function measure(
    metric::ModesNoveltyMetric, 
    all_genotypes::Set{<:Genotype}, 
    current_genotypes::Set{<:Genotype}
)
    new_genotypes = setdiff(current_genotypes, all_genotypes)
    novelty = length(new_genotypes)
    measurement = BasicMeasurement(metric, novelty)
    return measurement
end

@kwdef struct ModesChangeMetric <: Metric
    name::String = "change"
end

function measure(
    metric::ModesChangeMetric, 
    previous_genotypes::Set{<:Genotype}, 
    current_genotypes::Set{<:Genotype}
)
    different_genotypes = setdiff(current_genotypes, previous_genotypes)
    change = length(different_genotypes)
    measurement = BasicMeasurement(metric, change)
    return measurement
end

@kwdef struct ModesMetric <: Metric
    name::String = "modes"
    to_print::Union{String, Vector{String}} = ["novelty", "change", "complexity"]
    to_save::Union{String, Vector{String}} = "all"
end

end