export NumbersGameExperimentConfiguration, EvaluatorConfiguration, ReproducerConfiguration

using ....Abstract
using ...Reproducers.Basic: BasicReproducer
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...SpeciesCreators.Redisco: RediscoSpeciesCreator
using ...Selectors.Identity: IdentitySelector
using ...Evaluators.Disco: DiscoEvaluator
using ...Evaluators.Redisco: RediscoEvaluator

Base.@kwdef mutable struct EvaluatorConfiguration
    evaluator_type::String = "disco"
    objective::String = "outcomes"
    clusterer_type::String = "global_kmeans"
    distance_method::String = "euclidean"
    max_clusters::Int = 10
end

Base.@kwdef mutable struct ReproducerConfiguration
    id::String = "L"
    species_type::String = "basic"
    n_population::Int = 100
    n_elites::Int = 50
    n_parents::Int = 50
    n_children::Int = 50
    selection_type::String = "tournament"
    tournament_size::Int = 3
    max_archive_size::Int = 100
    n_dimensions::Int = 5
    initialization_range::Tuple{Float64, Float64} = (0.0, 0.1)
    discretize_phenotypes::Bool = true
    discretization_delta::Float64 = 0.25
    max_mutations::Int = 100
end

Base.@kwdef mutable struct NumbersGameExperimentConfiguration <: Configuration
    id::Int = 1
    learner_reproducer_config::ReproducerConfiguration = ReproducerConfiguration()
    distinguisher_reproducer_config::ReproducerConfiguration = ReproducerConfiguration()
    learner_evaluator_config::EvaluatorConfiguration = EvaluatorConfiguration()
    distinguisher_evaluator_config::EvaluatorConfiguration = EvaluatorConfiguration()
    domain::String = "CompareOnOne"
    seed::Int = abs(rand(Int))
    n_generations::Int = 5000
    n_workers::Int = 1
end

