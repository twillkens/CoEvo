module Roulette

export RouletteReproductionConfiguration, get_n_individuals, make_evaluator, make_replacer, make_selector

import ...ReproductionConfigurations: get_n_individuals, make_evaluator, make_replacer, make_selector

using ....Selectors.FitnessProportionate: FitnessProportionateSelector
using ....Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ...ReproductionConfigurations: ReproductionConfiguration
using ...ReproductionConfigurations: make_half_truncator

struct RouletteReproductionConfiguration <: ReproductionConfiguration
    id::String
    n_species::Int
    n_population::Int
    n_children::Int
end

function RouletteReproductionConfiguration(;
    id::String,
    n_species::Int = 2, 
    n_population::Int = 10, 
    n_children::Int = 10, 
    kwargs...
)
    reproduction = RouletteReproductionConfiguration(id, n_species, n_population, n_children)
    return reproduction
end

get_n_individuals(
    reproduction::RouletteReproductionConfiguration
) = reproduction.n_population + reproduction.n_children

make_evaluator(::RouletteReproductionConfiguration) = ScalarFitnessEvaluator()

make_replacer(
    reproduction::RouletteReproductionConfiguration
) = make_half_truncator(reproduction)

make_selector(
    reproduction::RouletteReproductionConfiguration
) = FitnessProportionateSelector(n_parents = reproduction.n_population)
end