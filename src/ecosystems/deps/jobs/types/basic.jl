module Basic

export BasicJob, BasicJobCreator

using DataStructures: OrderedDict
using ..Jobs.Abstract: Job, JobCreator
using ...Ecosystems.Abstract: Ecosystem
using ...Interactions.Abstract: Interaction
using ...Interactions.MatchMakers.Matches.Abstract: Match
using ...Species.Phenotypes.Abstract: Phenotype

import ..Interfaces: create_jobs


struct BasicJob{I <: Interaction, P <: Phenotype, M <: Match} <: Job
    interactions::OrderedDict{String, I}
    phenotypes::Dict{Int, P}
    matches::Vector{M}
end


Base.@kwdef struct BasicJobCreator{I <: Interaction} <: JobCreator
    interactions::OrderedDict{String, I} 
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

using ...Species.Phenotypes.Interfaces: create_phenotype

function create_phenotypes(
    all_species::Dict{String, <:AbstractSpecies},
    pheno_creators::Dict{String, <:PhenotypeCreator}
)
    phenotypes = Dict(
        indiv_id => create_phenotype(pheno_creators[species_id], indiv.geno)
        for (species_id, species) in all_species
        for (indiv_id, indiv) in merge(species.pop, species.children)
    )
    return phenotypes
end

import ...Interactions.MatchMakers.Interfaces: make_matches
using ...Species.Abstract: AbstractSpecies
using ...Species.Phenotypes.Abstract: PhenotypeCreator

function create_jobs(
    job_creator::BasicJobCreator, 
    all_species::Dict{String, <:AbstractSpecies},
    phenotype_creators::Dict{String, <:PhenotypeCreator}
)
    matches = vcat(
        [
            make_matches(interaction.matchmaker, all_species) 
            for interaction in values(job_creator.interactions)
        ]...
    )
    match_partitions = make_partitions(matches, job_creator.n_workers)
    pheno_dict = create_phenotypes(all_species, phenotype_creators)
    jobs = [
        BasicJob(job_creator.interactions, pheno_dict, match_partition)
        for match_partition in match_partitions
    ]
    return jobs
end

end
