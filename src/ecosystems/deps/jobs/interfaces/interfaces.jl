module Interfaces

export create_jobs

using ..Abstract: JobCreator, Ecosystem

function create_jobs(job_creator::JobCreator, eco::Ecosystem)
    throw(ErrorException("create_jobs not implemented for $(typeof(job_creator))"))
end

end