export create_report, create_reports, print_reports

function create_report(reporter::Reporter, state::State)::Report
    throw(ErrorException("create_report not implemented for $reporter and $state"))
end

function create_reports(reporters::Vector{<:Reporter}, state::State)
    reports = [create_report(reporter, state) for reporter in reporters]
    return reports
end

function print_reports(reporter::Reporter, reports::Vector{Report})
    throw(ErrorException("print_reports not implemented for $reporter and $reports"))
end
