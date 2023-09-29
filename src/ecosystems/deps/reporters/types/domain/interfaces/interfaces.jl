
module Interfaces

export create_report

using ..Abstract: DomainReporter


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