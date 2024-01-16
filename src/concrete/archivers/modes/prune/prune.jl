module Prune

export PruneSpecies, get_individuals, is_fully_pruned

import .....Interfaces: get_individuals_to_evaluate, get_individuals
using .....Abstract


include("individuals.jl")

struct PruneSpecies{I <: PruneIndividual} <: AbstractSpecies
    id::String
    currents::Vector{I}
    candidates::Vector{I}
    pruned::Vector{I}
end

function PruneSpecies(id::String, individuals::Vector{PruneIndividual{G}}) where {G <: Genotype}
    to_prune = individuals
    candidates = PruneIndividual{G}[]
    pruned = PruneIndividual{G}[]
    species = PruneSpecies(id, to_prune, candidates, pruned)
    return species
end

function is_fully_pruned(species::PruneSpecies)
    return length(species.currents) == 0
end

function is_fully_pruned(all_species::Vector{<:PruneSpecies})
    return all(is_fully_pruned, all_species)
end

function get_individuals_to_evaluate(species::PruneSpecies)
    individuals = length(species.candidates) == 0 ? 
        species.currents : species.candidates
    return individuals
end

using ....Ecosystems.Simple
using ....Species.Basic: BasicSpecies 
using .....Interfaces
using ....Evaluators.ScalarFitness: ScalarFitnessEvaluator




include("perform.jl")

end