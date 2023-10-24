export create_jobs

function create_jobs(
    job_creator::JobCreator,
    random_number_generator::AbstractRNG,
    all_species::Vector{<:AbstractSpecies},
    phenotype_creators::Vector{<:PhenotypeCreator},
)
    throw(ErrorException("`create_jobs` not implemented for $(typeof(job_creator))"))
end
