import CoEvo.Individuals: get_individuals

struct ModesSpecies{I <: BasicIndividual, M <: ModesIndividual} <: AbstractSpecies
    id::String
    normal_individuals::Vector{I}
    modes_individuals::Vector{M}
end

function is_fully_pruned(species::ModesSpecies)
    return length(species.modes_individuals) == 0
end

function is_fully_pruned(all_species::Vector{<:ModesSpecies})
    return all(is_fully_pruned, all_species)
end

function get_maximum_complexity(species::ModesSpecies)
    maximum_complexity = get_maximum_complexity(species.modes_individuals)
    return maximum_complexity
end

function get_maximum_complexity(all_species::Vector{<:ModesSpecies})
    maximum_complexity = maximum([get_maximum_complexity(species) for species in all_species])
    return maximum_complexity
end

function get_individuals(species::ModesSpecies)
    all_individuals = [species.normal_individuals ; species.modes_individuals]
    return all_individuals
end

function get_genes_to_check(genotype::FunctionGraphGenotype)
    gene_ids = sort(genotype.hidden_node_ids, rev = true)
    return gene_ids
end

function ModesSpecies(
    species::BasicSpecies{BasicIndividual{G}}, persistent_ids::Set{Int}
) where {G <: Genotype}
    normal_individuals = get_individuals(species)
    modes_individuals = ModesIndividual{G}[]
    for individual in normal_individuals
        if individual.id in persistent_ids
            genotype = minimize(individual.genotype)
            # println("chosen: ", individual.id, ", from ", persistent_ids, ", with size: ", get_size(genotype))
            modes_individual = ModesIndividual(-individual.id, genotype)
            push!(modes_individuals, modes_individual)
        end
    end
    #println(modes_individuals)
    modes_species = ModesSpecies(species.id, normal_individuals, modes_individuals)
    return modes_species
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

function get_all_ids(all_species::Vector{<:AbstractSpecies})
    all_individuals = vcat([get_individuals(species) for species in all_species]...)
    all_ids = Set(individual.id for individual in all_individuals)
    return all_ids
end