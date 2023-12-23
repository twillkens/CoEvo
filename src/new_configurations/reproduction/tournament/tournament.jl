module Tournament

export TournamentReproductionConfiguration

import ...ReproductionConfigurations: make_evaluator, make_replacer, make_selector
import ...ReproductionConfigurations: get_n_individuals

using ....Evaluators.NSGAII: NSGAIIEvaluator
using ....Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ....Selectors.Tournament: TournamentSelector
using ...ReproductionConfigurations: make_half_truncator, ReproductionConfiguration

struct TournamentReproductionConfiguration <: ReproductionConfiguration
    id::String
    n_species::Int
    n_population::Int
    n_children::Int
    tournament_size::Int
end

function TournamentReproductionConfiguration(;
    id::String = "tournament",
    n_species::Int = 2, 
    n_population::Int = 10, 
    n_children::Int = 10, 
    tournament_size::Int = 3,
    kwargs...
)
    reproduction = TournamentReproductionConfiguration(
        id, n_species, n_population, n_children, tournament_size)
    return reproduction
end

function make_evaluator(::TournamentReproductionConfiguration)
    evaluator = ScalarFitnessEvaluator()
    return evaluator
end

make_replacer(
    reproduction::TournamentReproductionConfiguration
) = make_half_truncator(reproduction)

make_selector(reproduction::TournamentReproductionConfiguration) = TournamentSelector(
    n_parents = reproduction.n_population, tournament_size = reproduction.tournament_size
)

end