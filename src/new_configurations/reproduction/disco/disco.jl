module Disco

export DiscoReproductionConfiguration, make_evaluator, make_replacer, make_selector, get_n_individuals

import ...ReproductionConfigurations: make_evaluator, make_replacer, make_selector
import ...ReproductionConfigurations: get_n_individuals

using ....Evaluators.NSGAII: NSGAIIEvaluator
using ....Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ....Selectors.Tournament: TournamentSelector
using ...ReproductionConfigurations: make_half_truncator, ReproductionConfiguration

struct DiscoReproductionConfiguration <: ReproductionConfiguration
    id::String
    n_species::Int
    n_population::Int
    n_children::Int
    tournament_size::Int
    max_clusters::Int
    clusterer::String
    distance_method::String
end

function DiscoReproductionConfiguration(;
    id::String = "disco",
    n_species::Int = 2, 
    n_population::Int = 10, 
    n_children::Int = 10, 
    tournament_size::Int = 5,
    max_clusters::Int = 5,
    clusterer::String = "global_kmeans",
    distance_method::String = "euclidean",
    kwargs...
)
    tournament_size = n_population <= 50 ? 3 : 5
    reproduction = DiscoReproductionConfiguration(
        id,
        n_species,
        n_population,
        n_children,
        tournament_size,
        max_clusters,
        clusterer,
        distance_method,
    )
    return reproduction
end

get_n_individuals(
    reproduction::DiscoReproductionConfiguration
) = reproduction.n_population + reproduction.n_children

function make_evaluator(reproduction::DiscoReproductionConfiguration)
    evaluator = NSGAIIEvaluator(
        maximize = true, 
        perform_disco = true, 
        max_clusters = reproduction.max_clusters,
        scalar_fitness_evaluator = ScalarFitnessEvaluator(),
        clusterer = reproduction.clusterer,
        distance_method = reproduction.distance_method,
    )
    return evaluator
end

make_replacer(reproduction::DiscoReproductionConfiguration) = make_half_truncator(reproduction)

function make_selector(reproduction::DiscoReproductionConfiguration)
    selector = TournamentSelector(
        n_parents = reproduction.n_population, 
        tournament_size = reproduction.tournament_size
    )
    return selector
end


end