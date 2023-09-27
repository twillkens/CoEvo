
module Abstract

abstract type Job end

abstract type Result end

function perform(::J)::Vector{Result} where {J <: Job}
    throw(ErrorException(
        "`perform` not implemented for job $J"
        )
    )
end

abstract type JobCreator end 


end