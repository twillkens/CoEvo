module Interfaces

export create_report

using ..Abstract: SpeciesReporter

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