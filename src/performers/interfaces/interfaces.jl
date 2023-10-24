module Interfaces

export perform

using ..Performers.Abstract: Performer
using ...Jobs.Abstract: Job

function perform(performer::Performer, jobs::Vector{<:Job})
    throw(ErrorException(
        "`perform` not implemented for performer $performer and job $jobs"
        )
    )
end

end