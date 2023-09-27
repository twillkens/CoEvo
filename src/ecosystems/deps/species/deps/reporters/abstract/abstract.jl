module Abstract

export SpeciesReport, SpeciesReporter

using ....Ecosystems.Abstract: Report, Reporter

abstract type SpeciesReporter <: Reporter end
abstract type SpeciesReport <: Report end

function create_report(
    reporter::SpeciesReporter,
    gen::Int,
    species_id::String,
    cohort::String,
    values::Vector{Float64}
)
    throw(ErrorException("create_report not implemented for $reporter"))
end

end