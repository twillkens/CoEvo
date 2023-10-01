module Interfaces

export create_jobs

using ..Jobs.Abstract: JobCreator
using ...Ecosystems.Abstract: Ecosystem

function create_jobs(job_creator::JobCreator, eco::Ecosystem)
    throw(ErrorException("create_jobs not implemented for $(typeof(job_creator))"))
end

end