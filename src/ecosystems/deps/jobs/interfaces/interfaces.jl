module Interfaces

export create_jobs

using Random: AbstractRNG

using ..Jobs.Abstract: JobCreator
using ...Ecosystems.Abstract: Ecosystem
using ...Ecosystems.Species.Abstract: AbstractSpecies, SpeciesCreator

function create_jobs(
    job_creator::JobCreator,
    rng::AbstractRNG,
    species_creators::Dict{String, <:SpeciesCreator},
    all_species::Dict{String, <:AbstractSpecies},
)
    throw(ErrorException("create_jobs not implemented for $(typeof(job_creator))"))
end

end