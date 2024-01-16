export perform

using ..Abstract

function perform(performer::Performer, jobs::Vector{<:Job})
    performer = typeof(performer)
    jobs = typeof(jobs)
    error("perform not implemented for $performer, $jobs")
end