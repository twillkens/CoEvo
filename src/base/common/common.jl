# Contains the common functions and types used by the other modules.
# Includes abstract types and functions, keys, observations, counters, genes, species, recipes, and outcomes.
module Common
export Gene, Individual, IndivConfig, Genotype, Phenotype, PhenoConfig
export Domain, Order, JobConfig, Result #, Outcome
export Observation, ObsConfig
export Replacer, Selector, Recombiner, Mutator
export Logger, Coevolution
export Job, Archiver
export SpawnCounter, gid!, iid!, gids!, iids!
export Random
export StableRNGs

using Random

include("abstract.jl")
include("keys.jl")
include("observation.jl")
include("counter.jl")
include("evostate.jl")
include("gene.jl")
include("species.jl")
include("recipe.jl")
include("outcomes.jl")
include("veteran.jl")
include("pheno.jl")

end