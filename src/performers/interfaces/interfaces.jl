export perform

using ..Jobs: Job

function perform(performer::Performer, jobs::Vector{<:Job})
    throw(ErrorException(
        "`perform` not implemented for performer $performer and job $jobs"
        )
    )
end
