module Evaluations

export TestBasedFitness, AllSpeciesFitness

using ..Metrics.Abstract: Metric

Base.@kwdef struct TestBasedFitness <: Metric 
    name::String = "TestBasedFitness"
end

Base.@kwdef struct AllSpeciesFitness <: Metric 
    name::String = "AllSpeciesFitness"
end

end