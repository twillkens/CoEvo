module Types

export BasicInteraction

using ..Interactions.Abstract: Interaction
using ..MatchMakers.Abstract: MatchMaker
using ..Observers.Abstract: Observer
using ..Environments.Abstract: EnvironmentCreator

Base.@kwdef struct BasicInteraction{
    E <: EnvironmentCreator, 
    M <: MatchMaker, 
    O <: Observer, 
} <: Interaction
    id::String
    environment_creator::E
    species_ids::Vector{String}
    matchmaker::M
    observers::Vector{O} = Observer[]
end

end