module Modes

export perform_modes, perform_modes_simulation!, process_next_generation!
export update_species_individuals!

using Random: AbstractRNG
using ...Genotypes: minimize
using ...Species: AbstractSpecies
using ...Species.Basic: BasicSpecies
using ...Species.Modes: ModesSpecies
using ...Species.Modes: create_modes_species, remove_pruned_individuals!
using ...SpeciesCreators: SpeciesCreator, get_phenotype_creators, get_scalar_fitness_evaluators
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Jobs: JobCreator, create_jobs
using ...Jobs.Basic: BasicJobCreator
using ...Interactions.Basic: BasicInteraction
using ...Performers: Performer, perform
using ...Performers.Basic: BasicPerformer
using ...Observers.Modes: PhenotypeStateObserver
using ...Results: get_individual_outcomes, get_observations
using ...Evaluators: evaluate, get_scaled_fitness
using ...Individuals.Modes: ModesIndividual, modes_prune, is_fully_pruned
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeState
using ...Observers: get_observations, Observer
using ...MatchMakers.AllVersusAll: AllVersusAllMatchMaker
using ...Phenotypes: create_phenotype
using ...Phenotypes.FunctionGraphs.Linearized: LinearizedFunctionGraphPhenotypeCreator

function create_modes_interaction(interaction::BasicInteraction, observers::Vector{<:Observer})
    interaction = BasicInteraction(
        interaction.id,
        interaction.environment_creator,
        interaction.species_ids,
        AllVersusAllMatchMaker(),
        observers,
    )
    return interaction
end

using ...Jobs.Basic: make_all_matches, create_phenotype_dict

function perform_modes_simulation!(
    performer::BasicPerformer, 
    random_number_generator::AbstractRNG,
    species_creators::Vector{<:BasicSpeciesCreator}, 
    job_creator::JobCreator, 
    all_species::Vector{<:ModesSpecies},
)
    phenotype_creators = get_phenotype_creators(species_creators)
    evaluators = get_scalar_fitness_evaluators(species_creators)
    # TODO: Refactor to make generic
    interactions = map(job_creator.interactions) do interaction
        observer = PhenotypeStateObserver{LinearizedFunctionGraphPhenotypeState}()
        interaction = create_modes_interaction(interaction, [observer])
    end
    job_creator = BasicJobCreator(interactions, job_creator.n_workers)
    #matches = make_all_matches(job_creator, random_number_generator, all_species)
    #phenotype_dict = create_phenotype_dict(all_species, phenotype_creators, matches)
    jobs = create_jobs(
        job_creator, random_number_generator, all_species, phenotype_creators
    )
    results = perform(performer, jobs)
    outcomes = get_individual_outcomes(results)
    observations = get_observations(results)
    evaluations = evaluate(evaluators, random_number_generator, all_species, outcomes)
    for species in all_species
        for modes_individual in species.modes_individuals
            modes_individual.fitness = get_scaled_fitness(evaluations, modes_individual.id)
            individual_observations = get_observations(observations, modes_individual.id)
            states = vcat([observation.states for observation in individual_observations]...)
            for node_id in modes_individual.prunable_genes
                for state in states
                    if node_id ∉ keys(state.node_values)
                        throw(ErrorException("Hidden node ID $node_id not found in state: $state."))
                    end
                end
            end
            modes_individual.states = states
        end
    end
end

# Process the next generation of individuals
function process_next_generation!(all_species::Vector{<:ModesSpecies})
    all_next_species = map(all_species) do species
        if is_fully_pruned(species)
            return species
        end
        next_individuals = map(species.modes_individuals) do modes_individual
            node_to_check = popfirst!(modes_individual.prunable_genes)
            next_individual = modes_prune(modes_individual, node_to_check)
            return next_individual
        end
        ids = [individual.id for individual in next_individuals]
        if length(ids) != length(unique(ids))
            throw(ErrorException("Species $(species.id) has $(length(ids)) individuals but $(length(unique(ids))) unique ids."))
        end
        next_species = ModesSpecies(
            species.id, species.normal_individuals, next_individuals
        )
        return next_species
    end
    return all_next_species
end

# Update species individuals
function update_species(
    all_species::Vector{<:ModesSpecies}, 
    all_next_species::Vector{<:ModesSpecies}, 
)
    all_species = map(zip(all_species, all_next_species)) do (species, next_species)
        if is_fully_pruned(species)
            return species
        end
        individuals = species.modes_individuals
        next_individuals = next_species.modes_individuals
        if length(individuals) != length(next_individuals)
            throw(ErrorException("Species $(species.id) has $(length(individuals)) individuals but $(length(next_individuals)) next individuals."))
        end
        new_individuals = [
            individual.fitness <= next_individual.fitness ? next_individual : individual 
            for (individual, next_individual) in zip(individuals, next_individuals)
        ]
        ids = [individual.id for individual in new_individuals]
        if length(ids) != length(unique(ids))
            throw(ErrorException("Species $(species.id) has $(length(ids)) individuals but $(length(unique(ids))) unique ids."))
        end
        new_species = ModesSpecies(species.id, species.normal_individuals, new_individuals)
        return new_species
    end
    return all_species
end

function perform_modes(
    performer::Performer,
    rng::AbstractRNG,
    species_creators::Vector{<:BasicSpeciesCreator}, 
    job_creator::JobCreator,
    all_species::Vector{<:ModesSpecies},
    fully_pruned_individuals::Dict{String, Vector{ModesIndividual}}
)
    i = 0
    perform_modes_simulation!(
        performer, rng, species_creators, job_creator, all_species
    )
    while !is_fully_pruned(all_species)
        i += 1
        all_next_species = process_next_generation!(all_species)
        perform_modes_simulation!(
            performer, rng, species_creators, job_creator, all_next_species
        )
        all_species = update_species(all_species, all_next_species)
        remove_pruned_individuals!(all_species, fully_pruned_individuals)
    end

    return fully_pruned_individuals
end

function perform_modes(
    performer::Performer,
    species_creators::Vector{<:BasicSpeciesCreator}, 
    job_creator::JobCreator,
    rng::AbstractRNG,
    all_species::Vector{<:AbstractSpecies},
    persistent_ids::Set{Int}
)
    all_modes_species = create_modes_species(all_species, persistent_ids)
    # TODO: Fix hack for control by adding topology etc to ecosystem_creator
    fully_pruned_individuals = Dict(species.id => ModesIndividual[] for species in all_species)
    if first(job_creator.interactions).id == "Control-A-B"
        for species in all_modes_species
            for modes_individual in species.modes_individuals
                genotype = minimize(modes_individual.genotype)
                modes_individual = ModesIndividual(modes_individual.id, genotype)
                push!(fully_pruned_individuals[species.id], modes_individual)
            end
        end
        return fully_pruned_individuals
    end

    remove_pruned_individuals!(all_modes_species, fully_pruned_individuals)

    if is_fully_pruned(all_modes_species)
        pruned = vcat(collect(values(fully_pruned_individuals))...)
        if isempty(pruned)
            throw(ErrorException("All individuals are fully pruned but none were stored."))
        end
        return fully_pruned_individuals
    end

    perform_modes(
        BasicPerformer(performer.n_workers), rng, species_creators, job_creator, all_modes_species, 
        fully_pruned_individuals
    )

end

end