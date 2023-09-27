module Abstract

export SpeciesReport, SpeciesReporter

using ....Ecosystems.Abstract: Report, Reporter
using ..Metrics.Abstract: Metric

abstract type SpeciesReporter{M <: Metric} <: Reporter end
abstract type SpeciesReport{M <: Metric} <: Report end

function create_report(
    reporter::SpeciesReporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool
    species_id::String,
    cohort::String,
    values::Vector{Float64}
)
    throw(ErrorException("create_report not implemented for $reporter"))
end

end