module Types

export BasicInteraction

module Basic

export BasicInteraction

using ...Abstract: Interaction
using ...MatchMakers.Abstract: MatchMaker
using ...Observers.Abstract: Observer
using ...Environments.Abstract: EnvironmentCreator

Base.@kwdef struct BasicInteraction{
    E <: EnvironmentCreator, 
    M <: MatchMaker, 
    O <: Observer, 
} <: Interaction
    id::String
    env_creator::E
    species_ids::Vector{String}
    matchmaker::M
    observers::Vector{O}
end

end

using .Basic: BasicInteraction


end