module Basic

export BasicDomainReport, BasicDomainReporter

using ..Abstract: DomainReport, DomainReporter, Metric, Observation, ObservationMetric
using ..Abstract: DomainMetric, MeasureSet

# TODO: Finish reports
struct BasicDomainReport{
    O <: ObservationMetric, 
    D <: DomainMetric, 
    M <: MeasureSet
} <: DomainReport{O, D, M}
    gen::Int
    to_print::Bool
    to_save::Bool
    domain_id::String
    observation_metric::O
    domain_metric::D
    measure_set::M
    print_measures::Vector{Symbol}
    save_measures::Vector{Symbol}
end

function Base.show(
    io::IO, 
    report::BasicDomainReport{O, D, M}
) where {
    O <: ObservationMetric, D <: DomainMetric, M <: MeasureSet
}
    println(io, "----------------------DOMAIN-------------------------------")
    println(io, "Generation $(report.gen)")
    println(io, "Domain ID: $(report.domain_id)")
    println(io, "Metric: $(report.metric)")
    println(io, "       Data: $(report.data)")
    
end

Base.@kwdef struct BasicDomainReporter{
    D <: DomainMetric
} <: DomainReporter{D}
    metric::D
    domain_ids::Vector{String}
    print_interval::Int = 1
    save_interval::Int = 0
    n_round::Int = 3
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end


end