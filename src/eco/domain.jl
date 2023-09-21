abstract type Problem end
abstract type DomainConfiguration end

Base.@kwdef struct DomainCfg{
    P <: Problem, M <: MatchMaker, PC <: PhenotypeConfiguration, O <: ObservationConfiguration, 
} <: DomainConfiguration
    problem::P
    species_ids::Vector{String}
    matchmaker::M = AllvsAllMatchMaker(:plus)
    pheno_cfgs::Vector{PC}
    obs_cfg::O = NullObsCfg()
end
