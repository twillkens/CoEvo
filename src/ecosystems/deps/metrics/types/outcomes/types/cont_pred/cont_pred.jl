module ContinuousPredictionGame

export Control, Competitive, CooperativeMatching, CooperativeMismatching

using ...Outcomes.Abstract: OutcomeMetric

Base.@kwdef struct Control <: OutcomeMetric
    name::String = "ControlMetric"
end

Base.@kwdef struct Competitive <: OutcomeMetric
    name::String = "CompetitiveGameMetric"
end

Base.@kwdef struct CooperativeMatching <: OutcomeMetric
    name::String = "CooperativeMatchingGameMetric"
end

Base.@kwdef struct CooperativeMismatching <: OutcomeMetric
    name::String = "CooperativeMismatchingGameMetric"
end
end