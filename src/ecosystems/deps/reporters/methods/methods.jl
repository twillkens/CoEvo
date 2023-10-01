module Methods

using ..Reporters.Abstract: Report, Reporter
using ...Interactions.Observers.Abstract: Observation
using ...Species.Evaluators.Abstract: Evaluation
using ...Species.Abstract: AbstractSpecies

import ..Reporters.Interfaces: create_reports

function create_reports(
    reporter::Reporter,
    gen::Int,
    species::Dict{String, AbstractSpecies},
    evaluations::Dict{String, Evaluation},
    observations::Vector{Observation},
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    create_reports(
        reporter,
        gen,
        to_print,
        to_save,
        species,
        evaluations,
        observations,
    )
end

end