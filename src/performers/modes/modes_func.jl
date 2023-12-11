module ModesFunc

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
using ...Observers.Modes: PhenotypeStateObserver
using ...Results: get_individual_outcomes, get_observations
using ...Evaluators: evaluate, get_scaled_fitness
using ...Individuals.Modes: ModesIndividual, modes_prune!, is_fully_pruned
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

function perform_modes_simulation!(
    performer::Performer, 
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
    jobs = create_jobs(
        job_creator, random_number_generator, all_species, phenotype_creators
    )
    results = perform(performer, jobs)
    outcomes = get_individual_outcomes(results)
    observations = get_observations(results)
    evaluations = evaluate(evaluators, random_number_generator, all_species, outcomes)
    for species in all_species
        for modes_individual in species.modes_individuals
            phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
            phenotype = create_phenotype(phenotype_creator, modes_individual.genotype, modes_individual.id)
            if length(phenotype.nodes) != length(modes_individual.genotype.nodes)
                println("Individual: ", modes_individual)
                println("Phenotype: ", phenotype)
                throw(ErrorException("Phenotype nodes $(length(phenotype.nodes)) != genotype nodes $(length(modes_individual.genotype.nodes))"))
            end
            modes_individual.fitness = get_scaled_fitness(evaluations, modes_individual.id)
            individual_observations = get_observations(observations, modes_individual.id)
            states = vcat([observation.states for observation in individual_observations]...)
            for node_id in modes_individual.prunable_genes
                for state in states
                    if node_id ∉ keys(state.node_values)
                        println("Individual: ", modes_individual)
                        println("Phenotype: ", phenotype)
                        println("States: ", states[1:10])
                        throw(ErrorException("Hidden node ID $node_id not found in state: $state."))
                    end
                end
            end
            modes_individual.states = states
        end
    end
end

# Process the next generation of individuals
function process_next_generation!(all_modes_species::Vector{<:ModesSpecies})
    all_next_modes_species = map(all_modes_species) do species
        next_individuals = map(species.modes_individuals) do modes_individual
            
            next_individual = modes_prune!(modes_individual)
            return next_individual
        end
        ModesSpecies(species.id, species.normal_individuals, next_individuals)
    end
    return all_next_modes_species
end

# Update species individuals
function update_species_individuals!(
    all_modes_species::Vector{<:ModesSpecies}, 
    next_modes_species::Vector{<:ModesSpecies}, 
    pruned_individuals::Dict{String, Vector{ModesIndividual}}
)
    for (modes_species, next_modes_species) in zip(all_modes_species, next_modes_species)
        pruned_ids = Set{Int}()
        for i in eachindex(modes_species.modes_individuals)
            modes_individual = modes_species.modes_individuals[i]
            next_modes_individual = next_modes_species.modes_individuals[i]
            if modes_individual.fitness <= next_modes_individual.fitness
                if is_fully_pruned(next_modes_individual)
                    push!(pruned_individuals[modes_species.id], next_modes_individual)
                    push!(pruned_ids, next_modes_individual.id)
                else
                    modes_species.modes_individuals[i] = next_modes_individual
                end
            elseif is_fully_pruned(modes_individual)
                push!(pruned_individuals[modes_species.id], modes_individual)
                push!(pruned_ids, modes_individual.id)
            end
        end
        filter!(individual -> individual.id ∉ pruned_ids, modes_species.modes_individuals)
    end
end

function perform_modes(
    performer::Performer,
    species_creators::Vector{<:BasicSpeciesCreator}, 
    job_creator::JobCreator,
    rng::AbstractRNG,
    all_species::Vector{<:BasicSpecies},
    persistent_ids::Set{Int}
)
    all_modes_species = create_modes_species(all_species, persistent_ids)
    # TODO: Fix hack for control by adding topology etc to ecosystem_creator
    pruned_individuals = Dict(species.id => ModesIndividual[] for species in all_species)
    if first(job_creator.interactions).id == "Control-A-B"
        for species in all_modes_species
            for modes_individual in species.modes_individuals
                genotype = minimize(modes_individual.genotype)
                modes_individual = ModesIndividual(modes_individual.id, genotype)
                push!(pruned_individuals[species.id], modes_individual)
            end
        end
        return pruned_individuals
    end

    for species in all_modes_species
        remove_pruned_individuals!(species, pruned_individuals)
    end

    if is_fully_pruned(all_modes_species)
        pruned = vcat(collect(values(pruned_individuals))...)
        if isempty(pruned)
            throw(ErrorException("All individuals are fully pruned but none were stored."))
        end
        return pruned_individuals
    end

    perform_modes_simulation!(performer, rng, species_creators, job_creator, all_modes_species)

    while !is_fully_pruned(all_modes_species)
        all_next_modes_species = process_next_generation!(all_modes_species)
        perform_modes_simulation!(
            performer, rng, species_creators, job_creator, all_next_modes_species
        )
        update_species_individuals!(
            all_modes_species, all_next_modes_species, pruned_individuals
        )
    end

    return pruned_individuals
end

end