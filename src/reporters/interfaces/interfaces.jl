export create_report, create_reports

function create_report(reporter::Reporter, state::State)::Report
    throw(ErrorException("create_report not implemented for $reporter and $state"))
end

function create_reports(reporters::Vector{<:Reporter}, state::State)
    reports = [create_report(reporter, state) for reporter in reporters]
    return reports
end
