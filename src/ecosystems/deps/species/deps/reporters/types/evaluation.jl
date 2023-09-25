export FitnessEvaluationReporter

using DataStructures: OrderedDict
using ....CoEvo.Abstract: Reporter, FitnessEvaluation, DomainConfiguration, Evaluation
using ....CoEvo.Utilities.Statistics: StatisticalFeatureSet
using .Abstract: EvaluationCohortMetricReporter

Base.@kwdef struct FitnessEvaluationReporter <: EvaluationCohortMetricReporter
    metric::String = "Fitness"
    print_interval::Int = 1
    save_interval::Int = 0
    check_pop::Bool = true
    check_children::Bool = true
    n_round::Int = 2
    print_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
    save_features::Vector{Symbol} = [:mean, :std, :minimum, :maximum]
end

function(reporter::FitnessEvaluationReporter)(
    gen::Int,
    species_id::String,
    generational_type::String,
    evaluations::Vector{<:Evaluation}
)
    fitnesses = map(evaluation -> evaluation.fitness, evaluations)
    report = reporter(gen, species_id, generational_type, fitnesses)
    return report
end
