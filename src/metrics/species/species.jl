module Species

export SpeciesMetric, SnapshotSpeciesMetric, measure
export AggregateSpeciesMetric, aggregate, AllGenotypesSpeciesMetric, ParentIDsSpeciesMetric
#export AdaptiveSpeciesIDsMetric

import ..Metrics: measure, get_name, aggregate

using ...Species: AbstractSpecies, get_individuals
using ...Species.Basic: BasicSpecies
#using ...Species.AdaptiveArchive: AdaptiveArchiveSpecies
using ...Evaluators: Evaluation
#using ...Evaluators.AdaptiveArchive: AdaptiveArchiveEvaluation
using ...Metrics: Metric, Measurement
using ...Metrics.Common: BasicMeasurement
using ...Metrics.Aggregators: Aggregator
using ...Metrics.Aggregators: BasicStatisticalAggregator, BasicQuantileAggregator
using ...Metrics.Aggregators: OneSampleTTestAggregator, HigherMomentAggregator
using ...Metrics.Genotypes: GenotypeMetric
using ...Metrics.Evaluations: EvaluationMetric

abstract type SpeciesMetric <: Metric end

function measure(metric::SpeciesMetric, all_species::Vector{<:AbstractSpecies})
    measurements = vcat([measure(metric, species) for species in all_species]...)
    return measurements
end

function measure(metric::SpeciesMetric, evaluations::Vector{<:Evaluation})
    measurements = vcat([measure(metric, evaluation) for evaluation in evaluations]...)
    return measurements
end

struct SnapshotSpeciesMetric <: SpeciesMetric end

function measure(::SnapshotSpeciesMetric, species::BasicSpecies)
    measurements = Measurement[]
    species_path = "species/$(species.id)"
    population_ids = [individual.id for individual in species.population]
    population_id_measurement = BasicMeasurement("$species_path/population_ids", population_ids)
    push!(measurements, population_id_measurement)
    for child in species.children
        child_path = "$species_path/children/$(child.id)"
        parent_ids_measurement = BasicMeasurement("$child_path/parent_ids", child.parent_ids)
        push!(measurements, parent_ids_measurement)
        genotype_measurement = BasicMeasurement("$child_path/genotype", child.genotype)
        push!(measurements, genotype_measurement)
    end
    return measurements
end

struct AllGenotypesSpeciesMetric <: SpeciesMetric end

function measure(::AllGenotypesSpeciesMetric, species::BasicSpecies)
    measurements = Measurement[]
    population_path = "species/$(species.id)/population"
    individuals = [species.population; species.children]
    measurements = [
        BasicMeasurement("$population_path/$(individual.id)/genotype", individual.genotype)
        for individual in individuals
    ]
    return measurements
end

using ...Species.Modes: ModesSpecies

function measure(::AllGenotypesSpeciesMetric, species::ModesSpecies)
    population_genotype_measurements = [
        BasicMeasurement("species/$(species.id)/population/$(individual.id)/genotype", individual.genotype)
        for individual in species.population
    ]
    population_parent_id_measurements = [
        BasicMeasurement(
            "species/$(species.id)/population/$(individual.id)/parent_id", individual.parent_id
        )
        for individual in species.population
    ]
    pruned_genotype_measurements = [
        BasicMeasurement("species/$(species.id)/pruned/$(individual.id)/genotype", individual.genotype)
        for individual in species.pruned
    ]
    population_age_measurements = [
        BasicMeasurement(
            "species/$(species.id)/population/$(individual.id)/age", individual.age
        )
        for individual in species.population
    ]

    measurements = [
        population_genotype_measurements;
        population_parent_id_measurements;
        pruned_genotype_measurements;
        population_age_measurements;
    ]
    return measurements

end


#measure(metric::AllGenotypesSpeciesMetric, species::AdaptiveArchiveSpecies) = measure(
#    metric, species.basic_species
#)

struct ParentIDsSpeciesMetric <: SpeciesMetric end

function measure(::ParentIDsSpeciesMetric, species::BasicSpecies)
    measurements = Measurement[]
    population_path = "species/$(species.id)/population"
    for child in species.children
        child_id = child.id
        parent_ids_path = "$population_path/$child_id/parent_ids"
        parent_ids_measurement = BasicMeasurement(parent_ids_path, child.parent_ids)
        push!(measurements, parent_ids_measurement)
    end
    for individual in species.population
        individual_id = individual.id
        parent_ids_path = "$population_path/$individual_id/parent_ids"
        parent_ids = [individual.id]
        parent_ids_measurement = BasicMeasurement(parent_ids_path, parent_ids)
        push!(measurements, parent_ids_measurement)
    end
    return measurements
end

# function measure(metric::ParentIDsSpeciesMetric, species::AdaptiveArchiveSpecies)
#     measurements = measure(metric, species.basic_species)
#     return measurements
# end

Base.@kwdef struct AggregateSpeciesMetric{M <: Metric, A <: Aggregator} <: SpeciesMetric
    submetric::M
    name::String = "species"
    cohorts::Vector{String} = ["population"]
    aggregators::Vector{A} = [
        BasicStatisticalAggregator(),
        BasicQuantileAggregator(),
        OneSampleTTestAggregator(),
    ]
    to_print::Union{String, Vector{String}} = ["mean", "maximum", "minimum", "std"]
    to_save::Union{String, Vector{String}} = "all"
end

function measure(
    metric::AggregateSpeciesMetric{<:GenotypeMetric, <:Aggregator}, species::AbstractSpecies
)
    individuals = get_individuals(species, metric.cohorts)
    genotypes = [individual.genotype for individual in individuals]
    measurements = [measure(metric.submetric, genotype) for genotype in genotypes]
    submetric_name = get_name(metric.submetric)
    base_path = "species/$(species.id)/$submetric_name"
    measurements = aggregate(metric.aggregators, base_path, measurements)
    return measurements
end

function measure(
    metric::AggregateSpeciesMetric{<:EvaluationMetric, <:Aggregator}, evaluation::Evaluation
)
    measurements = measure(metric.submetric, evaluation)
    submetric_name = get_name(metric.submetric)
    base_path = "species/$(evaluation.id)/$submetric_name"
    measurements = aggregate(metric.aggregators, base_path, measurements)
    return measurements
end


end