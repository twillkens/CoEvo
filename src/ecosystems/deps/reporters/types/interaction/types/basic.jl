module Basic

export BasicInteractionReport, BasicInteractionReporter

using ..Abstract: InteractionReport, InteractionReporter, Metric, Observation, ObservationMetric
using ..Abstract: OutcomeMetric, MeasureSet
using ....Ecosystems.Metrics.Interaction.Abstract: InteractionMetric

# TODO: Finish reports
struct BasicInteractionReport{
    O <: ObservationMetric, 
    I <: InteractionMetric, 
    M <: MeasureSet
} <: InteractionReport{O, I, M}
    gen::Int
    to_print::Bool
    to_save::Bool
    interaction_id::String
    observation_metric::O
    outcome_metric::I
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
    println(io, "Metric: $(report.outcome_metric)")
    println(io, "       Data: $(report.observation_metric)")
    
end

Base.@kwdef struct BasicInteractionReporter{
    I <: InteractionMetric
} <: InteractionReporter{I}
    metric::I
    interaction_ids::Vector{String}
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 3
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end


end