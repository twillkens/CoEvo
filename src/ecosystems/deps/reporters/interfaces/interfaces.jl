module Interfaces

export create_reports

using ..Abstract: Reporter, Observation, Individual, Evaluation

function create_reports(
    reporter::Reporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    observations::Vector{Observation},
    species_evaluations::Dict{String, Dict{String, Dict{Individual, Evaluation}}}
)
    throw(ErrorException("create_report not implemented for $reporter"))
end

end