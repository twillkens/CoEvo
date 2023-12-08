

# Function to create ModesSpecies objects
function create_modes_species(all_species::Vector{<:AbstractSpecies}, persistent_ids::Set{Int})
    return [ModesSpecies(species, persistent_ids) for species in all_species]
end

# Function to prune individuals
function prune_individuals!(
    species::ModesSpecies, pruned_individuals::Vector{<:ModesIndividual}
)
    pruned_ids = Set{Int}()
    for individual in species.modes_individuals
        if is_fully_pruned(individual)
            push!(pruned_individuals, individual)
            push!(pruned_ids, individual.id)
        end
    end
    filter!(individual -> individual.id ∉ pruned_ids, species.modes_individuals)
    return pruned_ids
end

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

# Process the next generation of individuals
function process_next_generation!(
    all_modes_species::Vector{<:ModesSpecies}
)
    all_next_modes_species = map(all_modes_species) do species
        next_individuals = map(species.modes_individuals) do modes_individual
            modes_prune!(modes_individual)
        end
        ModesSpecies(species.id, species.normal_individuals, next_individuals)
    end
    return all_next_modes_species
end

# Update species individuals
function update_species_individuals!(
    all_modes_species::Vector{<:ModesSpecies}, 
    next_modes_species::Vector{<:ModesSpecies}, 
    pruned_individuals::Vector{<:ModesIndividual}
)
    for (modes_species, next_modes_species) in zip(all_modes_species, next_modes_species)
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

function get_modes_results(
    species_creators::Vector{<:SpeciesCreator}, 
    job_creator::JobCreator,
    performer::Performer,
    rng::AbstractRNG,
    all_species::Vector{<:AbstractSpecies},
    persistent_ids::Set{Int}
)
    all_modes_species = create_modes_species(all_species, persistent_ids)
    pruned_individuals = ModesIndividual[]

    for species in all_modes_species
        prune_individuals!(species, pruned_individuals)
    end

    if is_fully_pruned(all_modes_species)
        if isempty(pruned_individuals)
            println("All individuals are fully pruned but none were stored.")
            throw(ErrorException("All individuals are fully pruned but none were stored."))
        end
        return pruned_individuals
    end

    perform_modes_simulation!(all_modes_species, species_creators, job_creator, performer, rng)

    while !is_fully_pruned(all_modes_species)
        all_next_modes_species = process_next_generation!(all_modes_species)
        perform_modes_simulation!(all_next_modes_species, species_creators, job_creator, performer, rng)
        update_species_individuals!(all_modes_species, all_next_modes_species, pruned_individuals)
    end

    return pruned_individuals
end
