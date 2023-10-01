module Types

export EpisodeLengthMetric

using ..Abstract: InteractionMetric

Base.@kwdef struct EpisodeLengthMetric <: InteractionMetric
    name::String = "Episode Length"
end


end