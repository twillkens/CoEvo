module Common

export AbsoluteError, NullMetric, RuntimeMetric, AllSpeciesIdentity

using ...Metrics.Abstract: Metric

Base.@kwdef struct AbsoluteError <: Metric
    name::String = "AbsoluteError"
end

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