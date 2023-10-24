export create_report

function create_report(reporter::Reporter, state::State)::Report
    throw(ErrorException("create_report not implemented for $reporter and $state"))
end