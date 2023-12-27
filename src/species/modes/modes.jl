module Modes

export ModesSpecies, get_individuals, get_persistent_tags, get_children, get_elders
export ModesSpecies, get_individuals_to_evaluate, add_elites_to_archive
export get_persistent_tags, get_children, get_elders
export get_population, get_previous_population, get_pruned, get_previous_pruned
export get_pruned_fitnesses, get_previous_pruned_fitnesses, get_elites, get_previous_elites
export get_individuals_to_evaluate, get_individuals_to_perform, get_previous_individuals_to_perform
export get_children, get_elders, get_persistent_tags, get_population_genotypes
export get_minimized_population_genotypes, get_pruned_genotypes, get_previous_pruned_genotypes
export get_all_previous_pruned_genotypes, get_elites

import ...Individuals: get_individuals
import ...Species: get_individuals_to_evaluate, get_individuals_to_perform
import Base: length

using ...Genotypes: get_size
using Random: AbstractRNG
using StatsBase: sample, mean, Weights
using ...Individuals: Individual
using ...Individuals.Basic: BasicIndividual
using ...Individuals.Modes: ModesIndividual
using ...Species: AbstractSpecies

include("species.jl")

include("getters.jl")

include("elites.jl")

end