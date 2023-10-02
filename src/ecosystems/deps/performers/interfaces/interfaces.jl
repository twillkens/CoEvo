module Interfaces

export perform

using ..Performers.Abstract: Performer
using ...Jobs.Abstract: Job

function perform(performer::Performer, job::Job)
    throw(ErrorException(
        "`perform` not implemented for performer $performer and job $job"
        )
    )
end

end