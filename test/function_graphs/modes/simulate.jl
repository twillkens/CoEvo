
function perform_modes_simulation!(
    all_species::Vector{<:ModesSpecies},
    species_creators::Vector{<:SpeciesCreator}, 
    job_creator::JobCreator, 
    performer::Performer, 
    random_number_generator::AbstractRNG,
)
    phenotype_creators = get_phenotype_creators(species_creators)
    evaluators = get_scalar_fitness_evaluators(species_creators)
    interactions = map(job_creator.interactions) do interaction
        BasicInteraction(interaction, [FunctionGraphModesObserver()])
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
            modes_individual.fitness = get_scaled_fitness(evaluations, modes_individual.id)
            modes_individual.observations = get_observations(observations, modes_individual.id)
        end
    end
end

function get_modes_results(
    species_creators::Vector{<:SpeciesCreator}, 
    job_creator::JobCreator,
    performer::Performer,
    rng::AbstractRNG,
    all_species::Vector{<:AbstractSpecies},
    persistent_ids::Set{Int}, 
)
    all_modes_species = [ModesSpecies(species, persistent_ids) for species in all_species]
    pruned_individuals = ModesIndividual[]
    for species in all_modes_species
        pruned_ids = Set{Int}()
        for modes_individual in species.modes_individuals
            if is_fully_pruned(modes_individual)
                push!(pruned_individuals, modes_individual)
                push!(pruned_ids, modes_individual.id)
            end
        end
        filter!(individual -> individual.id ∉ pruned_ids, species.modes_individuals)
    end
    if is_fully_pruned(all_modes_species)
        if length(pruned_individuals) == 0
            modes_individuals = [
                species.modes_individuals 
                for species in all_modes_species 
            ]
            println("all_modes_individuals: $modes_individuals")
            throw(ErrorException("All individuals are fully pruned but none were stored."))
        end
        return pruned_individuals
    end
    counter = 0
    perform_modes_simulation!(all_modes_species, species_creators, job_creator, performer, rng)
    while !is_fully_pruned(all_modes_species)
        all_next_modes_species = map(all_modes_species) do species
            next_individuals = map(species.modes_individuals) do modes_individual
                next_individual = modes_prune!(modes_individual)
                return next_individual
            end
            next_species = ModesSpecies(species.id, species.normal_individuals, next_individuals)
            return next_species
        end
        counter += 1
        perform_modes_simulation!(
            all_next_modes_species, species_creators, job_creator, performer, rng
        )
        for (modes_species, next_modes_species) in zip(all_modes_species, all_next_modes_species)
            pruned_ids = Set{Int}()
            for i in eachindex(modes_species.modes_individuals)
                modes_individual = modes_species.modes_individuals[i]
                next_modes_individual = next_modes_species.modes_individuals[i]
                if modes_individual.fitness <= next_modes_individual.fitness
                    if is_fully_pruned(next_modes_individual)
                        push!(pruned_individuals, next_modes_individual)
                        push!(pruned_ids, next_modes_individual.id)
                    else
                        modes_species.modes_individuals[i] = next_modes_individual
                    end
                elseif is_fully_pruned(modes_individual)
                    push!(pruned_individuals, modes_individual)
                    push!(pruned_ids, modes_individual.id)
                end
            end
            filter!(individual -> individual.id ∉ pruned_ids, modes_species.modes_individuals)
        end
    end
    return pruned_individuals
end