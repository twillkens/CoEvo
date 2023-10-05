module ContinuousPredictionGame

export Control, Competitive, CooperativeMatching, CooperativeMismatching

using ...Outcomes.Abstract: OutcomeMetric

# Both are rewarded regardless
Base.@kwdef struct Control <: OutcomeMetric
    name::String = "ControlMetric"
end

# The first is rewarded if it matches, the second if it mismatches
Base.@kwdef struct Competitive <: OutcomeMetric
    name::String = "CompetitiveGameMetric"
end

# Both are rewarded if they match
Base.@kwdef struct CooperativeMatching <: OutcomeMetric
    name::String = "CooperativeMatchingGameMetric"
end

# Both are rewarded if they mismatch
Base.@kwdef struct CooperativeMismatching <: OutcomeMetric
    name::String = "CooperativeMismatchingGameMetric"
end
end