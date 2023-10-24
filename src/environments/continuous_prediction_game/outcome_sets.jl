
function get_outcome_set(
    environment::ContinuousPredictionGameEnvironment{D, <:Phenotype, <:Phenotype}
) where {D <: PredictionGameDomain}
    # As pi is the maximum distance between two entities, and the episode begins with them
    # maximally distant, the maximum distance score is pi * episode_length in the case
    # where the entities never move.
    maximum_distance_score = π * environment.episode_length
    distance_score = sum(environment.distances) / maximum_distance_score
    outcome_set = measure(environment.domain, distance_score)
    return outcome_set
end