export create_jobs

using ..Abstract

function create_jobs(job_creator::JobCreator, ecosystem::Ecosystem, state::State)
    job_creator = typeof(job_creator)
    ecosystem = typeof(ecosystem)
    state = typeof(state)
    error("create_jobs not implemented for $job_creator, $ecosystem, $state")
end