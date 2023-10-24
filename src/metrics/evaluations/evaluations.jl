module Evaluations

export TestBasedFitness, AllSpeciesFitness, AbsoluteError

using ..Metrics: Metric

Base.@kwdef struct TestBasedFitness <: Metric 
    name::String = "TestBasedFitness"
end

Base.@kwdef struct AllSpeciesFitness <: Metric 
    name::String = "AllSpeciesFitness"
end

@kwdef struct AbsoluteError <: Metric
    name::String = "AbsoluteError"
end

end