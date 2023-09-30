module Interfaces

export perform

using ..Abstract: Job, Performer

function perform(performer::Performer, job::Job)
    throw(ErrorException(
        "`perform` not implemented for performer $performer and job $job"
        )
    )
end

end