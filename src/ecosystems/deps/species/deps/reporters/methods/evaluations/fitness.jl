using ....CoEvo.Abstract: Evaluation
using ....CoEvo.Utilities.Metrics: EvaluationFitness

function(reporter::CohortMetricReporter{EvaluationFitness})(
    gen::Int,
    species_id::String,
    cohort::String,
    evaluations::Vector{<:Evaluation}
)
    fitnesses = [eval.fitness for eval in evaluations]
    report = reporter(gen, species_id, cohort, fitnesses)
    return report
end