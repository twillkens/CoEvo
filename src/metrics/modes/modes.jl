module Modes

export ComplexityMetric, NoveltyMetric, ChangeMetric

import ...Metrics: measure

using Base: @kwdef
using ...Genotypes: Genotype, get_size
using ...Metrics: Metric, Measurement
using ...Metrics.Common: BasicMeasurement

@kwdef struct ComplexityMetric <: Metric
    name::String = "complexity"
end

using ...Abstract.States: State, get_species, get_all_species

function get_current_pruned_genotypes(state::State)
    all_species = get_all_species(state)
    genotypes = [
        individual.genotype 
        for species in all_species 
        for individual in species.pruned_individuals
    ]
    return genotypes
end

function get_previous_pruned_genotypes(state::State)
    all_species = get_all_species(state)
    genotypes = [
        individual.genotype 
        for species in all_species 
        for individual in species.previous_pruned
    ]
    return genotypes
end

function get_all_previous_pruned_genotypes(state::State)
    all_species = get_all_species(state)
    genotypes = [
        individual.genotype 
        for species in all_species 
        for individual in species.all_previous_pruned
    ]
    return genotypes
end

using ...Metrics.Aggregators: BasicStatisticalAggregator, aggregate

function measure(::ComplexityMetric, state::State)
    genotypes = get_current_pruned_genotypes(state)
    complexities = [get_size(genotype) for genotype in genotypes]
    measurements = aggregate(
        BasicStatisticalAggregator(), 
        "modes/complexity", 
        [BasicMeasurement("complexity", complexity) for complexity in complexities]
    )
    return measurements
end

@kwdef struct NoveltyMetric <: Metric
    name::String = "novelty"
end

function measure(::NoveltyMetric, state::State)
    current_pruned = get_current_pruned_genotypes(state)
    all_previous_pruned = get_all_previous_pruned_genotypes(state)
    new_genotypes = setdiff(current_pruned, all_previous_pruned)
    novelty = length(new_genotypes)
    measurement = BasicMeasurement("modes/novelty", novelty)
    return measurement
end

@kwdef struct ChangeMetric <: Metric
    name::String = "change"
end

function measure(::ChangeMetric, state::State)
    current_pruned = get_current_pruned_genotypes(state)
    previous_pruned = get_previous_pruned_genotypes(state)
    different_genotypes = setdiff(current_pruned, previous_pruned)
    change = length(different_genotypes)
    measurement = BasicMeasurement("modes/change", change)
    return measurement
end

@kwdef struct ModesMetric <: Metric
    name::String = "modes"
    to_print::Union{String, Vector{String}} = ["novelty", "change", "complexity"]
    to_save::Union{String, Vector{String}} = "all"
end

end