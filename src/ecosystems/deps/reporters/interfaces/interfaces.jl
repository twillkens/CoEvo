module Interfaces

export create_reports

using ..Reporters.Abstract: Report, Reporter
using ...Ecosystems.Interactions.Observers.Abstract: Observation
using ...Ecosystems.Species.Abstract: AbstractSpecies
using ...Ecosystems.Species.Evaluators: Evaluation

function create_reports(
    reporter::Reporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    species::Dict{String, AbstractSpecies},
    evaluations::Dict{String, Evaluation},
    observations::Vector{Observation},
)::Vector{Report}
    throw(ErrorException("create_report not implemented for $reporter"))
end

end