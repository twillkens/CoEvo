module Abstract

export DomainReport, DomainReporter, DomainMetric, Report, Reporter, Metric
export create_report

using .....Ecosystems.Abstract: Report, Reporter, Metric
using ...Observers.Abstract: Observation

abstract type DomainReport <: Report end

abstract type DomainReporter{M2 <: Metric, M2 <: Metric} <: Reporter end

abstract type DomianMetric <: Metric end

function create_report(
    reporter::DomainReporter,
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    domain_id::String,
    observations::Vector{Observation}
)::DomainReport
    throw(ErrorException("Default report creation for $reporter not implemented."))
end

end