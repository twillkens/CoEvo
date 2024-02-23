module Simple

export SimpleEcosystem, SimpleEcosystemCreator

import ....Interfaces: create_ecosystem, update_ecosystem!, create_ecosystem_with_time
import ....Interfaces: convert_to_dict, create_from_dict, evaluate
using ....Abstract: Ecosystem, EcosystemCreator, State, AbstractSpecies
using ....Abstract
using ....Utilities: find_by_id
using ....Interfaces: create_species, update_species!

struct SimpleEcosystem{S <: AbstractSpecies} <: Ecosystem
    id::Int
    all_species::Vector{S}
end

Base.@kwdef struct SimpleEcosystemCreator <: EcosystemCreator 
    id::Int
end

Base.getindex(ecosystem::SimpleEcosystem, species_id::String) = begin
    species = filter(species -> species.id == species_id, ecosystem.all_species)
    if length(species) == 0
        error("Species with id $species_id not found in ecosystem")
    end
    return first(species)
end

function create_ecosystem(
    eco_creator::SimpleEcosystemCreator, reproducers::Vector{<:Reproducer}, state::State
)
    all_species = [
        create_species(reproducer.species_creator, reproducer, state)
        for reproducer in reproducers
    ]
    new_ecosystem = SimpleEcosystem(eco_creator.id, all_species)
    return new_ecosystem
end


function validate_ecosystem(ecosystem::SimpleEcosystem, state::State)
    all_individuals = [
        individual for species in ecosystem.all_species for individual in species.population
    ]
    all_individual_ids = [individual.id for individual in all_individuals]
    if length(all_individuals) != length(Set(all_individual_ids))
        println("all_individual_ids = $all_individual_ids")
        error("individual ids are not unique AFTER")
    end
end

function update_ecosystem!(
    ecosystem::SimpleEcosystem, 
    ::SimpleEcosystemCreator, 
    evaluations::Vector{<:Evaluation}, 
    reproducers::Vector{<:Reproducer},
    state::State
)
    for species in ecosystem.all_species
        evaluation = find_by_id(evaluations, species.id)
        reproducer = find_by_id(reproducers, species.id)
        species_creator = reproducer.species_creator
        update_species!(species, species_creator, evaluation, reproducer, state)
    end
end

function convert_to_dict(ecosystem::SimpleEcosystem)
    dict = Dict(
        "ID" => ecosystem.id,
        "SPECIES" => Dict(
            species.id => convert_to_dict(species) for species in ecosystem.all_species
        )
    )
    return dict
end

function create_from_dict(::SimpleEcosystemCreator, dict::Dict, state::State)
    id = dict["ID"]
    species_dict = dict["SPECIES"]
    all_species = [
        create_from_dict(state.reproducer.species_creator, species_dict, state)
        for species_dict in values(species_dict)
    ]
    sort!(all_species, by = species -> species.id)
    ecosystem = SimpleEcosystem(id, all_species)
    return ecosystem
end

function evaluate(
    ecosystem::SimpleEcosystem, 
    evaluators::Vector{<:Evaluator}, 
    results::Vector{<:Result}, 
    state::State
)
    evaluations = map(ecosystem.all_species) do species
        evaluator = find_by_id(evaluators, species.id)
        evaluation = evaluate(evaluator, species, results, state)
	if state.generation > 1
		push!(state.evaluations, evaluation)
	end
        return evaluation
    end
    if state.generation > 1
	    empty!(state.evaluations)
    end
    return evaluations
end

end
