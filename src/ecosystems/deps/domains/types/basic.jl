module Basic

export BasicDomain

using ..Abstract: Domain
using ..Domains.Abstract: DomainCreator
using ..MatchMakers.Abstract: MatchMaker
using ..Observers.Abstract: Observer
using ..Environments.Abstract: EnvironmentCreator

Base.@kwdef struct BasicDomain{
    E <: EnvironmentCreator, 
    M <: MatchMaker, 
    O <: Observer, 
} <: Domain
    id::String
    env_creator::E
    species_ids::Vector{String}
    matchmaker::M
    observers::Vector{O}
end

end