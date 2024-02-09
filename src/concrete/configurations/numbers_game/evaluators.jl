export create_evaluators, create_evaluator

import ....Interfaces: create_evaluator, create_evaluators

function create_evaluator(config::EvaluatorConfiguration)
    if config.evaluator_type == "scalar_fitness"
        evaluator = ScalarFitnessEvaluator(
            id = config.id,
            maximize = true,
            objective = config.objective
        )
    elseif config.evaluator_type == "disco"
        evaluator = DiscoEvaluator(
            id = config.id,
            maximize = true, 
            objective = config.objective,
            max_clusters = config.max_clusters,
            clusterer = config.clusterer_type,
            distance_method = config.distance_method
        )
    elseif config.evaluator_type == "redisco"
        evaluator = RediscoEvaluator(
            id = config.id,
            max_clusters = config.max_clusters,
        )
    else
        error("Invalid evaluator type: $(config.evaluator_type)")
    end
    return evaluator
end

function create_evaluators(config::NumbersGameExperimentConfiguration)
    evaluators = [
        create_evaluator(config.learner_evaluator_config),
        create_evaluator(config.distinguisher_evaluator_config)
    ]
    return evaluators
end