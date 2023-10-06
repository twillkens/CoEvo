module CollisionGameOutcomeMetrics

export Control, Affinitive, Adversarial, Avoidant

using ....Metrics.Abstract: Metric


Base.@kwdef struct Control <: Metric 
    name::String = "Control"
end

Base.@kwdef struct Affinitive <: Metric 
    name::String = "Affinitive"
end

Base.@kwdef struct Adversarial <: Metric 
    name::String = "Adversarial"
end

Base.@kwdef struct Avoidant <: Metric 
    name::String = "Avoidant"
end

end