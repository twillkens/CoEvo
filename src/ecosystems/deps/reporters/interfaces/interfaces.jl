module Interfaces

export create_report

using ..Abstract: SpeciesReporter

function create_report(
    reporter::SpeciesReporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    species_id::String,
    cohort::String,
    values::Vector{Float64}
)
    throw(ErrorException("create_report not implemented for $reporter"))
end

function create_report(
    reporter::DomainReporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    domain_id::String,
    observations::Vector{Observation}
)::DomainReport
    throw(ErrorException("create_report not implemented for $reporter"))
end

end