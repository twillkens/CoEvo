export get_persistent_tags, get_children, get_elders
export get_population, get_previous_population, get_pruned, get_previous_pruned
export get_pruned_fitnesses, get_previous_pruned_fitnesses, get_elites, get_previous_elites
export get_individuals_to_evaluate, get_individuals_to_perform, get_previous_individuals_to_perform
export get_children, get_elders, get_persistent_tags, get_population_genotypes
export get_minimized_population_genotypes, get_pruned_genotypes, get_previous_pruned_genotypes
export get_all_previous_pruned_genotypes, get_elites
export get_previous_elite_ids, get_elite_ids

import ...Species: get_population_genotypes, get_minimized_population_genotypes
import ...Species: get_individuals_to_perform, get_individuals_to_evaluate
import ...Species: get_population, get_elites
using ...Genotypes: minimize

# Current population
get_population(species::ModesSpecies) = species.current_state.population
get_elites(species::ModesSpecies) = species.current_state.elites
get_elite_ids(species::ModesSpecies) = species.current_state.elite_ids
get_pruned(species::ModesSpecies) = species.current_state.pruned
get_pruned_fitnesses(species::ModesSpecies) = species.current_state.pruned_fitnesses
get_pruned_genotypes(species::ModesSpecies) = [
    individual.genotype for individual in get_pruned(species)
]
get_pruned_genotypes(all_species::Vector{<:ModesSpecies}) = vcat(
    [get_pruned_genotypes(species) for species in all_species]...
)
get_population_genotypes(species::ModesSpecies) = [
    individual.genotype for individual in get_population(species)
]
get_population_genotypes(all_species::Vector{<:ModesSpecies}) = vcat(
    [get_population_genotypes(species) for species in all_species]...
)
get_minimized_population_genotypes(species::ModesSpecies) = [
    minimize(individual.genotype) for individual in get_population(species)
]
get_minimized_population_genotypes(all_species::Vector{<:ModesSpecies}) = vcat(
    [get_minimized_population_genotypes(species) for species in all_species]...
)
get_children(species::ModesSpecies) = [
    individual for individual in get_population(species) if individual.age == 0
]
get_elders(species::ModesSpecies) = [
    individual for individual in get_population(species) if individual.age > 0
]
get_persistent_tags(species::ModesSpecies) = Set(
    [individual.tag for individual in get_population(species)]
)

# Previous checkpoint population
get_previous_population(species::ModesSpecies) = species.previous_state.population
get_previous_elites(species::ModesSpecies) = species.previous_state.elites
get_previous_elite_ids(species::ModesSpecies) = species.previous_state.elite_ids
get_previous_pruned(species::ModesSpecies) = species.previous_state.pruned
get_previous_pruned_fitnesses(species::ModesSpecies) = species.previous_state.pruned_fitnesses
get_previous_pruned_genotypes(species::ModesSpecies) = [
    individual.genotype for individual in get_previous_pruned(species)
]
get_previous_pruned_genotypes(all_species::Vector{<:ModesSpecies}) = vcat(
    [get_previous_pruned_genotypes(species) for species in all_species]...
)
get_all_previous_pruned_genotypes(species::ModesSpecies) = species.all_previous_pruned

get_all_previous_pruned_genotypes(all_species::Vector{<:ModesSpecies}) = union(
    [get_all_previous_pruned_genotypes(species) for species in all_species]...
)

get_individuals_to_evaluate(species::ModesSpecies) = get_population(species)

get_individuals_to_perform(species::ModesSpecies,) = [
    get_population(species) ; 
    [individual for individual in get_elites(species) if individual.id in get_elite_ids(species)]
]
get_previous_individuals_to_perform(species::ModesSpecies) = [
    get_previous_population(species) ; 
    [individual for individual in get_previous_elites(species) if individual.id in get_previous_elite_ids(species)]

]