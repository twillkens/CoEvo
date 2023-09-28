module Abstract

export DomainReport, DomainReporter, DomainMetric
export create_report



abstract type DomainReport <: Report end

abstract type DomainReporter <: Reporter end

abstract type DomianMetric <: Metric end

function create_report(
    reporter::DomainReporter,
    gen::Int,
    to_print::Bool
    to_save::Bool
    domain_id::String,
    observations::Vector{Observation}
)::DomainReport
    throw(ErrorException("Default report creation for $reporter not implemented."))
end

end