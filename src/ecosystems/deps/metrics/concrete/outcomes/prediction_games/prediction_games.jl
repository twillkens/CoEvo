module PredictionGameOutcomeMetrics

export Control, Competitive, CooperativeMatching
export CooperativeMismatching

using ....Metrics.Abstract: Metric


# Both are rewarded regardless
Base.@kwdef struct Control <: Metric
    name::String = "ControlMetric"
end

# The first is rewarded if it matches, the second if it mismatches
Base.@kwdef struct Competitive <: Metric
    name::String = "CompetitiveGameMetric"
end

# Both are rewarded if they match
Base.@kwdef struct CooperativeMatching <: Metric
    name::String = "CooperativeMatchingGameMetric"
end

# Both are rewarded if they mismatch
Base.@kwdef struct CooperativeMismatching <: Metric
    name::String = "CooperativeMismatchingGameMetric"
end

end