export DensityClassificationExperimentConfiguration, EvaluatorConfiguration, ReproducerConfiguration

import ....Interfaces: get_ecosystem_creator
using ....Abstract
using ...Reproducers.Basic: BasicReproducer
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...SpeciesCreators.Redisco: RediscoSpeciesCreator
using ...Selectors.Identity: IdentitySelector
using ...Evaluators.Disco: DiscoEvaluator
using ...Evaluators.Redisco: RediscoEvaluator
using ...Ecosystems.Simple: SimpleEcosystemCreator


Base.@kwdef mutable struct EvaluatorConfiguration
    id::String = "L"
    evaluator_type::String = "disco"
    objective::String = "outcomes"
    clusterer_type::String = "global_kmeans"
    distance_method::String = "euclidean"
    max_clusters::Int = 10
    n_runs::Int = 10
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
    recombiner::String = "clone"
    max_archive_size::Int = 100
    n_dimensions::Int = 5
    max_mutations::Int = 1
    flip_chance::Float64 = 0.02
end

Base.@kwdef mutable struct DensityClassificationExperimentConfiguration <: Configuration
    id::Int = 1
    learner_reproducer_config::ReproducerConfiguration
    distinguisher_reproducer_config::ReproducerConfiguration
    learner_evaluator_config::EvaluatorConfiguration
    distinguisher_evaluator_config::EvaluatorConfiguration
    seed::Int = abs(rand(Int))
    n_generations::Int = 5000
    n_workers::Int = 1
end

get_ecosystem_creator(config::DensityClassificationExperimentConfiguration) = SimpleEcosystemCreator(config.id)
