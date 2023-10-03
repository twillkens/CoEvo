module Types

export EvaluationFitnessMetric

using .....Ecosystems.Metrics.Species.Evaluation.Abstract: EvaluationMetric

Base.@kwdef struct EvaluationFitnessMetric <: EvaluationMetric
    name::String = "EvaluationFitness"
end


end
