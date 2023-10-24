module Interfaces

export create_report

using ..Reporters.Abstract: Report, Reporter
using ...Ecosystems.Interactions.Observers.Abstract: Observation
using ...Ecosystems.Species.Abstract: AbstractSpecies
using ...Ecosystems.Species.Evaluators.Abstract: Evaluation
using ...Ecosystems.Interactions.Abstract: Interaction

function create_report(
    reporter::Reporter,
    gen::Int,
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    observations::Vector{<:Observation}
)::Report
    throw(ErrorException("create_report not implemented for $reporter"))
end

function measure(
    reporter::Reporter,
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    observations::Vector{<:Observation}
)
    throw(ErrorException("measure not implemented for $reporter"))
end

end