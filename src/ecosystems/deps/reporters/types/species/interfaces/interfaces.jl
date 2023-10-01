module Interfaces

export create_report

using ..Abstract: SpeciesReporter

using ....Ecosystems.Species.Abstract: AbstractSpecies
using ....Ecosystems.Species.Evaluators.Abstract: Evaluation

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

function measure(
    reporter::SpeciesReporter,
    species::AbstractSpecies,
    evaluation::Evaluation
)
    throw(ErrorException("measure not implemented for $reporter, $species, $evaluation"))
end

end