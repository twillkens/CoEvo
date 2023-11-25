using Distributed

@everywhere using CoEvo
@everywhere using CoEvo.ModesToolbox: ModesTrialReport

function create_modes_reports(;
    trials::Vector{Int} = collect(1:20),
    archive_directory::String = "/media/tcw/Seagate/two_comp/",
    perform_parallel::Bool = true,
    kwargs...
)
    # complete me
    if perform_parallel
        reports = pmap(trial -> ModesTrialReport(
            trial, archive_directory; kwargs...), trials
        )
    else
        reports = [
            ModesTrialReport(trial, archive_directory; kwargs...) 
            for trial in trials
        ]
    end
    return reports
end

