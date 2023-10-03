module Basic

export BasicJob, BasicJobCreator

using Random: AbstractRNG

using ..Jobs.Abstract: Job, JobCreator
using ...Ecosystems.Abstract: Ecosystem
using ...Interactions.Abstract: Interaction
using ...Interactions.MatchMakers.Matches.Abstract: Match
using ...Species.Phenotypes.Abstract: Phenotype
using ...Species.Abstract: AbstractSpecies, SpeciesCreator
using ...Species.Phenotypes.Interfaces: create_phenotype
using ...Species.Phenotypes.Abstract: PhenotypeCreator

import ..Jobs.Interfaces: create_jobs
import ...Interactions.MatchMakers.Interfaces: make_matches


struct BasicJob{I <: Interaction, P <: Phenotype, M <: Match} <: Job
    interactions::Dict{String, I}
    phenotypes::Dict{Int, P}
    matches::Vector{M}
end


Base.@kwdef struct BasicJobCreator{I <: Interaction} <: JobCreator
    interactions::Dict{String, I} 
    n_workers::Int = 1
end


function make_partitions(items::Vector{T}, n_partitions::Int) where T
    n = length(items)
    # Base size for each job
    base_size = div(n, n_partitions)
    # Number of jobs that will take an extra item
    extras = n % n_partitions
    partitions = Vector{Vector{T}}()
    start_idx = 1
    for _ in 1:n_partitions
        end_idx = start_idx + base_size - 1
        if extras > 0
            end_idx += 1
            extras -= 1
        end
        push!(partitions, items[start_idx:end_idx])
        start_idx = end_idx + 1
    end
    return partitions
end
"""
    (cfg::JobCfg)(eco::Ecosystem) -> Vector{InteractionResult}

Using the given job configuration, construct and execute interaction jobs based on the ecosystem. 
Results from all interactions are aggregated and returned.

# Arguments
- `cfg::JobCfg`: The job configuration detailing interactions and number of workers.
- `eco::Ecosystem`: The ecosystem providing entities for interaction.

# Returns
- A `Vector` of `InteractionResult` detailing outcomes of all interactions executed.
"""


function create_phenotypes(
    species_creators::Dict{String, <:SpeciesCreator},
    all_species::Dict{String, <:AbstractSpecies},
)
    pheno_creators = Dict(
        species_id => species_creator.pheno_creator
        for (species_id, species_creator) in species_creators
    )
    phenotypes = Dict(
        indiv_id => create_phenotype(pheno_creators[species_id], indiv.geno)
        for (species_id, species) in all_species
        for (indiv_id, indiv) in merge(species.pop, species.children)
    )
    return phenotypes
end

function create_jobs(
    job_creator::BasicJobCreator, 
    rng::AbstractRNG,
    species_creators::Dict{String, <:SpeciesCreator},
    all_species::Dict{String, <:AbstractSpecies},
)
    matches = vcat(
        [
            make_matches(
                interaction.matchmaker, 
                rng,
                interaction.id,
                all_species,
                interaction.species_ids
            ) 
            for interaction in values(job_creator.interactions)
        ]...
    )
    match_partitions = make_partitions(matches, job_creator.n_workers)
    phenotypes = create_phenotypes(species_creators, all_species)
    jobs = [
        BasicJob(job_creator.interactions, phenotypes, match_partition)
        for match_partition in match_partitions
    ]
    return jobs
end

end
