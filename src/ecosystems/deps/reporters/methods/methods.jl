module Methods

import ..Interfaces: create_reports

function create_reports(
    ::Reporter,
    gen::Int,
    observations::Vector{Observation},
    species_evaluations::Dict{String, Dict{String, Dict{<:Individual, <:Evaluation}}}
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    create_reports(
        reporter,
        gen,
        to_print,
        to_save,
        observations,
        species_evaluations
    )
end

end