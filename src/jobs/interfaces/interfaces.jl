module Interfaces

export create_jobs

using Random: AbstractRNG

using ..Jobs.Abstract: JobCreator
using ...Ecosystems.Abstract: Ecosystem
using ...Ecosystems.Species.Abstract: AbstractSpecies
using ...Ecosystems.Species.Phenotypes.Abstract: PhenotypeCreator

function create_jobs(
    job_creator::JobCreator,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AbstractSpecies},
    phenotype_creators::Vector{<:PhenotypeCreator},
)
    throw(ErrorException("`create_jobs` not implemented for $(typeof(job_creator))"))
end

end