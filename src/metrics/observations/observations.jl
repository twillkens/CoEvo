module Observations

export EpisodeLength

using ...Metrics: Metric

Base.@kwdef struct EpisodeLength <: Metric
    name::String = "Episode Length"
end

end