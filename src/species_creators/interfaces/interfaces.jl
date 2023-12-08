export create_species, get_scalar_fitness_evaluators, get_phenotype_creators

using ..Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ..Evaluators.NSGAII: NSGAIIEvaluator

function create_species(
    species_creator::SpeciesCreator,
    random_number_generator::AbstractRNG, 
    individual_id_counter::Counter,
    gene_id_counter::Counter
)::AbstractSpecies
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator"
        )
    )
end

function create_species(
    species_creator::SpeciesCreator,
    random_number_generator::AbstractRNG,
    individual_id_counter::Counter,
    gene_id_counter::Counter,
    species::AbstractSpecies,
    evaluation::Evaluation
)::AbstractSpecies
    throw(ErrorException(
        "`create_species` not implemented for species $species_creator "
        )
    )
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

function get_phenotype_creators(species_creators::Vector{<:SpeciesCreator})
    phenotype_creators = [
        species_creator.phenotype_creator for species_creator in species_creators
    ]
    return phenotype_creators
end