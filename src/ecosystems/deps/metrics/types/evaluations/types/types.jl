module Types

export TestBasedFitness

using ..Evaluations.Abstract: EvaluationMetric

Base.@kwdef struct TestBasedFitness <: EvaluationMetric 
    name::String = "TestBasedFitness"
end

end