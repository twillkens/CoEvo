using Distributed

@everywhere using CoEvo
@everywhere using CoEvo.ModesToolbox: ModesTrialReport

function create_modes_reports(;
    trials::Vector{Int} = collect(1:20),
    perform_parallel::Bool = true,
    kwargs...
)
    # complete me
    if perform_parallel
        reports = pmap(trial -> ModesTrialReport(trial = trial; kwargs...), trials)
    else
        reports = [ModesTrialReport(trial = trial; kwargs...) for trial in trials]
    end
    return reports
end

