export measure_complexity, measure_novelty, measure_change, measure_ecology

using ...Species.Modes: ModesSpecies, get_pruned, get_pruned_genotypes
using ...Species.Modes: get_previous_pruned_genotypes, get_all_previous_pruned_genotypes
using ...Genotypes: get_size
using ....Abstract.States: State, get_all_species, get_evaluations
using ...Archivers.Utilities: get_aggregate_measurements, measure_shannon_entropy

function get_complexities(species::ModesSpecies)
    complexities = [get_size(genotype) for genotype in get_pruned_genotypes(species)]
    return complexities
end

function get_complexities(all_species::Vector{<:ModesSpecies})
    complexities = vcat([get_complexities(species) for species in all_species]...)
    return complexities
end

function measure_complexity(all_species::Vector{<:ModesSpecies})
    complexities = get_complexities(all_species)
    aggregate_measurements = get_aggregate_measurements(complexities)
    complexity = Dict("complexity" => aggregate_measurements)
    return complexity
end

function measure_complexity(state::State)
    all_species = get_all_species(state)
    complexity = measure_complexity(all_species)
    return complexity
end

#function measure_novelty(all_species::Vector{<:ModesSpecies})
#    pruned_genotypes = get_pruned_genotypes(all_species)
#    all_previous_pruned_genotypes = get_all_previous_pruned_genotypes(all_species)
#    new_genotypes = setdiff(pruned_genotypes, all_previous_pruned_genotypes)
#    novelty = Dict("novelty" => length(new_genotypes))
#    return novelty
#end

#function measure_novelty(state::State)
#    all_species = get_all_species(state)
#    novelty = measure_novelty(all_species)
#    return novelty
#end

function measure_novelty(state::State)
    all_species = get_all_species(state)
    novelty = first(all_species).novelty
    return Dict("novelty" => novelty)
end

#function measure_change(all_species::Vector{<:ModesSpecies})
#    pruned_genotypes = get_pruned_genotypes(all_species)
#    previous_pruned_genotypes = get_previous_pruned_genotypes(all_species)
#    change = Dict("change" => length(setdiff(pruned_genotypes, previous_pruned_genotypes)))
#    return change
#end
#
#function measure_change(state::State)
#    all_species = get_all_species(state)
#    change = measure_change(all_species)
#    return change
#end

function measure_change(state::State)
    all_species = get_all_species(state)
    change = first(all_species).change
    return Dict("change" => change)
end

function measure_ecology(all_species::Vector{<:ModesSpecies})
    pruned_genotypes = get_pruned_genotypes(all_species)
    ecology = Dict("ecology" => measure_shannon_entropy(pruned_genotypes))
    return ecology
end

function measure_ecology(state::State)
    all_species = get_all_species(state)
    ecology = measure_ecology(all_species)
    return ecology
end
