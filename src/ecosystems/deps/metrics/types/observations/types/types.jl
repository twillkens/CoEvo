module Types

export TheVectorWithAverageClosestToPi, NullObservationMetric

using ..Abstract: ObservationMetric

struct TheVectorWithAverageClosestToPi <: ObservationMetric end

Base.@kwdef struct NullObservationMetric <: ObservationMetric 
    name::String = "NullObservationMetric"
end


end