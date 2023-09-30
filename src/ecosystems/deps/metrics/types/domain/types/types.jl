module Types

export EpisodeLengthMetric

using ..Abstract: DomainMetric

Base.@kwdef struct EpisodeLengthMetric <: DomainMetric
    name::String = "Episode Length"
end


end