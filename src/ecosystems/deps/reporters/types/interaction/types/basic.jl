module Basic

export BasicInteractionReport, BasicInteractionReporter

using ..Abstract: InteractionReport, InteractionReporter, Metric, Observation, ObservationMetric
using ..Abstract: OutcomeMetric, MeasureSet

# TODO: Finish reports
struct BasicInteractionReport{
    O <: ObservationMetric, 
    D <: OutcomeMetric, 
    M <: MeasureSet
} <: InteractionReport{O, D, M}
    gen::Int
    to_print::Bool
    to_save::Bool
    interaction_id::String
    observation_metric::O
    outcome_metric::D
    measure_set::M
    print_measures::Vector{Symbol}
    save_measures::Vector{Symbol}
end

function Base.show(
    io::IO, 
    report::BasicInteractionReport{O, D, M}
) where {
    O <: ObservationMetric, D <: OutcomeMetric, M <: MeasureSet
}
    println(io, "----------------------DOMAIN-------------------------------")
    println(io, "Generation $(report.gen)")
    println(io, "Interaction ID: $(report.interaction_id)")
    println(io, "Metric: $(report.metric)")
    println(io, "       Data: $(report.data)")
    
end

Base.@kwdef struct BasicInteractionReporter{
    D <: OutcomeMetric
} <: InteractionReporter{D}
    metric::D
    interaction_ids::Vector{String}
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 3
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end


end