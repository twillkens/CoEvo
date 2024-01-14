module EpisodeLength

import ....Interfaces: create_observation, observe!
using ....Abstract

Base.@kwdef mutable struct EpisodeLengthObserver <: Observer 
    is_active::Bool = false
    n_episodes::Int = 0
end

struct EpisodeLengthObservation <: Observation
    episode_length::Int
end


function observe!(observer::EpisodeLengthObserver, ::Any)
    if !observer.is_active
        return
    end
    observer.n_episodes += 1
end

function create_observation(observer::EpisodeLengthObserver)
    if !observer.is_active
        return EpisodeLengthObservation(0)
    end
    return EpisodeLengthObservation(observer.n_episodes)
end

end