module Interfaces

export perform

function perform(performer::Performer, job::Job)
    throw(ErrorException(
        "`perform` not implemented for performer $performer and job $job"
        )
    )
end

end