
module Interfaces

export create_report

using ..Abstract: InteractionReporter, Observation, InteractionReport


function create_report(
    reporter::InteractionReporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    interaction_id::String,
    observations::Vector{Observation}
)::InteractionReport
    throw(ErrorException("create_report not implemented for $reporter"))
end

end