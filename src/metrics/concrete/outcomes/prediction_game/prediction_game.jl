module PredictionGameOutcomeMetrics

export Control, Adversarial, Affinitive, Avoidant

using ....Metrics.Abstract: Metric

# Both are rewarded regardless
Base.@kwdef struct Control <: Metric
    name::String = "Control"
end

# The first is rewarded if it matches, the second if it mismatches
Base.@kwdef struct Adversarial <: Metric
    name::String = "Adversarial"
end

# Both are rewarded if they match
Base.@kwdef struct Affinitive <: Metric
    name::String = "Affinitive"
end

# Both are rewarded if they mismatch
Base.@kwdef struct Avoidant <: Metric
    name::String = "Avoidant"
end

end