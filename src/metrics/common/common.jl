module Common

export NullMetric, RuntimeMetric, AllSpeciesIdentity

using ...Metrics: Metric

Base.@kwdef struct NullMetric <: Metric 
    name::String = "NullMetric"
end

Base.@kwdef struct RuntimeMetric <: Metric
    name::String = "Runtime"
end

Base.@kwdef struct AllSpeciesIdentity <: Metric
    name::String = "AllSpeciesIdentity"
    minimize_genotype::Bool = false
end

end