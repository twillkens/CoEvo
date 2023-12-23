module Modes

export ModesSpecies, get_individuals, get_persistent_tags, get_children, get_elders
export ModesSpecies, get_individuals_to_evaluate, add_elites_to_archive

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