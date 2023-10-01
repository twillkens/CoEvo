module Basic

export BasicSpeciesReporter

using DataStructures: OrderedDict
using ..Species.Abstract: SpeciesReport, SpeciesReporter
using ....Metrics.Species.Abstract: SpeciesMetric
using ....Measures.Abstract: MeasureSet
using ..Abstract: Individual, Evaluation, Observation

import ..Interfaces: create_report

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
struct BasicSpeciesReport{MET <: SpeciesMetric, MEA <: MeasureSet} <: SpeciesReport{MET, MEA}
    gen::Int
    to_print::Bool
    to_save::Bool
    species_id::String
    metric::MET
    measure_set::MEA
    print_measures::Vector{Symbol}
    save_measures::Vector{Symbol}
end

# Custom display for BasicSpeciesReport
function Base.show(io::IO, report::BasicSpeciesReport)
    println(io, "----------------------SPECIES-------------------------------")
    println(io, "Generation $(report.gen)")
    println(io, "Species ID: $(report.species_id)")
    println(io, "Cohort: $(report.cohort)")
    println(io, "Metric: $(report.metric)")
    
    for measurement in report.print_measures
        value = getfield(report.measure_set, measurement)
        println(io, "    $measurement: $value")
    end
end

Base.@kwdef struct BasicSpeciesReporter{M <: SpeciesMetric} <: SpeciesReporter{M}
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 3
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end


end