abstract type Archivist end 

struct BasicEcosystem
    id::String
    species::Dict{String, Species}
end

"""
    EcosystemCfg{
        S <: Spawner,
        O <: Order,
        J <: JobConfiguration,
        A <: Archivist
    }

    Create an ecosystem configuration for a coevolutionary run. 
"""

struct BasicEcosystemCfg{
    S <: SpeciesConfiguration, 
    J <: JobConfiguration, 
    A <: Archivist
} <: EcosystemConfiguration
    id::String
    trial::Int
    rng::AbstractRNG
    species_cfgs::Vector{S}
    job_cfg::J
    archivist::A
    indiv_id_counter::Counter
    gene_id_counter::Counter
end

"""
    function EcosystemCfg(
        id::String = "eco", # Unique identifier for the ecosystem
        trial::Int = 1; # The trial number
        seed::Union{UInt64, Int}, # The seed for the random number generator
        spawners::Vector{<:Spawner},
        orders::Vector{<:Order},
        jobcfg::JobConfig = SerialPhenoJobConfig(), # Configuration for dispatching interaction jobs
        archivist::Archivist = NullArchivist(), # Log and persist information about the ecosystem
    )

    # Arguments
    - `id::String`: Unique identifier for the ecosystem
    - `trial::Int`: The trial number

"""
function BasicEcosystemCfg(
    species_cfgs::Vector{<:SpeciesCfg},
    job_cfg::JobConfiguration;
    id::String = "eco",
    trial::Int = 1,
    seed::Union{UInt64, Int} = -1,
    rng::Union{AbstractRNG, Nothing} = nothing,
    archivist::Archivist = NullArchivist(),
    indiv_id_counter::Counter = Counter(),
    gene_id_counter::Counter = Counter(),
)
    rng = rng !== nothing ? rng : seed == -1 ? StableRNG(rand(UInt32)) : StableRNG(seed)
    BasicEcosystemCfg(
        id, trial, rng, species_cfgs, job_cfg, archivist, indiv_id_counter, gene_id_counter
    )
end

function(eco_cfg::BasicEcosystemCfg)()
    species = Dict(
        species_cfg.id => species_cfg() for species_cfg in eco_cfg.species_cfgs
    )
    BasicEcosystem(eco_cfg.id, species)
end

function get_pheno_dict(eco::BasicEcosystem)
    Dict(
        indiv_id => species.pheno_cfg(indiv_id, indiv.geno)
        for (indiv_id, indiv) in merge(species.pop, species.children)
        for species in values(eco.species)
    )
end