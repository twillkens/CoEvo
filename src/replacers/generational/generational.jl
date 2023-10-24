module Generational

export GenerationalReplacer

import ...Replacers.Interfaces: replace

using Random: AbstractRNG
using ...Individuals: Individual
using ...Species.Abstract: AbstractSpecies
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluation
using ..Replacers.Abstract: Replacer

Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
end

function replace(
    replacer::GenerationalReplacer,
    ::AbstractRNG, 
    species::AbstractSpecies,
    evaluation::ScalarFitnessEvaluation
)
    population_ids = Set(individual.id for individual in values(species.population))
    children_ids = Set(individual.id for individual in values(species.children))
    population_records = [
        record for record in evaluation.records if record.id in population_ids
    ]
    children_records = [record for record in evaluation.records if record.id in children_ids]
    elite_ids = [record.id for record in population_records[1:replacer.n_elite]]
    n_children = length(species.population) - replacer.n_elite
    children_ids = [record.id for record in children_records[1:n_children]]
    new_population_ids = Set([elite_ids ; children_ids])
    all_individuals = [species.population ; species.children]
    new_population = filter(individual -> individual.id in new_population_ids, all_individuals)

    return new_population
end

end