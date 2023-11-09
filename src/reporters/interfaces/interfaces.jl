export create_report, create_reports

function create_report(reporter::Reporter, state::State)::Report
    throw(ErrorException("create_report not implemented for $reporter and $state"))
end

function create_reports(state::State, reporters::Vector{<:Reporter})
    reports = [create_report(reporter, state) for reporter in reporters]
    return reports
end