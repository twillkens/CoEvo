export create_jobs

using ..Abstract

function create_jobs(job_creator::JobCreator, ecosystem::Ecosystem, state::State)
    error("`create_jobs` not implemented for $(typeof(job_creator))")
end