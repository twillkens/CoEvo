export create_species, get_scalar_fitness_evaluators
export get_phenotype_creator, get_phenotype_creators
export get_evaluator, get_evaluators

using ..Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ..Evaluators.NSGAII: NSGAIIEvaluator
using ..Abstract.States: State

function create_species(species_creator::SpeciesCreator, state::State)::AbstractSpecies
    species_creator = typeof(species_creator)
    state = typeof(state)
    throw(ErrorException(
        "`create_species` not implemented for species creator $species_creator with state $state"
        )
    )
end

function create_species(
    species_creator::SpeciesCreator, species::AbstractSpecies, state::State
)::AbstractSpecies
    species_creator = typeof(species_creator)
    state = typeof(state)
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator with state $state"
        )
    )
end

function create_species(
    species_creators::Vector{<:SpeciesCreator},
    all_species::Vector{<:AbstractSpecies},
    state::State
)
    species = [
        create_species(species_creator, species, state)
        for (species_creator, species) in zip(species_creators, all_species)
    ]
    return species
end

function get_scalar_fitness_evaluators(species_creators::Vector{<:SpeciesCreator})
    evaluators = [species_creator.evaluator for species_creator in species_creators]
    evaluators = map(evaluators) do evaluator
        if typeof(evaluator) === ScalarFitnessEvaluator
            return evaluator
        elseif typeof(evaluator) === NSGAIIEvaluator
            return evaluator.scalar_fitness_evaluator
        else
            throw(ErrorException("Evaluator type $(typeof(evaluator)) not supported for MODES."))
        end
    end
    return evaluators
end

function get_phenotype_creator(species_creator::SpeciesCreator)
    phenotype_creator = species_creator.phenotype_creator
    return phenotype_creator
end

function get_phenotype_creators(species_creators::Vector{<:SpeciesCreator})
    phenotype_creators = [
        get_phenotype_creator(species_creator) for species_creator in species_creators
    ]
    return phenotype_creators
end

function get_evaluator(species_creator::SpeciesCreator)
    evaluator = species_creator.evaluator
    return evaluator
end

function get_evaluators(species_creators::Vector{<:SpeciesCreator})
    evaluators = [
        get_evaluator(species_creator) for species_creator in species_creators
    ]
    return evaluators
end
