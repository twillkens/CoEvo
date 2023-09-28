module Abstract

export Job, JobCreator, Result, perform

abstract type Job end

abstract type JobCreator end 

abstract type Result end

function perform(::Job)::Vector{Result}
    throw(ErrorException(
        "`perform` not implemented for job $J"
        )
    )
end

end