module Types

export EpisodeLengthMetric

using ..Abstract: OutcomeMetric

Base.@kwdef struct EpisodeLengthMetric <: OutcomeMetric
    name::String = "Episode Length"
end


end