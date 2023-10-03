module Types

export TestBasedFitness, AllSpeciesFitness

using ..Evaluations.Abstract: EvaluationMetric

Base.@kwdef struct TestBasedFitness <: EvaluationMetric 
    name::String = "TestBasedFitness"
end

Base.@kwdef struct AllSpeciesFitness <: EvaluationMetric 
    name::String = "AllSpeciesFitness"
end

end