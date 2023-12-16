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

function get_modes_interactions(prune_species::PruneSpecies, state::State)
    interactions = get_interactions(state)
    filter!(interaction -> prune_species.id in interaction.species_ids, interactions)

    # TODO: Refactor to make generic
    interactions = map(interactions) do interaction
        observer = PhenotypeStateObserver{LinearizedFunctionGraphPhenotypeState}()
        interaction = create_modes_interaction(interaction, [observer])
        return interaction
    end
    return interactions
end


struct SimpleSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
end

get_individuals(species::SimpleSpecies) = species.population

get_individuals_to_evaluate(species::SimpleSpecies) = species.population    


function get_modes_jobs(prune_species::PruneSpecies, state::State)
    interactions = get_modes_interactions(prune_species, state)
    job_creator = BasicJobCreator(interactions, get_n_workers(state))
    to_evaluate = get_individuals_to_evaluate(prune_species)
    simple_species = SimpleSpecies(prune_species.id, to_evaluate)
    other_simple_species = [
        SimpleSpecies(species.id, species.checkpoint_population) 
        for species in filter(species -> species.id != prune_species.id, get_all_species(state))
    ]
    all_simple_species = [simple_species ; other_simple_species]
    jobs = create_jobs(
        job_creator, get_rng(state), all_simple_species, get_phenotype_creators(state)
    )
    return jobs, simple_species
end

using ...Results: get_individual_outcomes, get_observations

function perform_evaluations(species::PruneSpecies, state::State)
    jobs, simple_species = get_modes_jobs(species, state)
    performer = BasicPerformer(get_n_workers(state))
    results = perform(performer, jobs)
    outcomes = Dict(id => value for (id, value) in get_individual_outcomes(results) if id < 0)
    evaluator = ScalarFitnessEvaluator()
    evaluation = evaluate(evaluator, get_rng(state), simple_species, outcomes)
    observations = get_observations(results)
    return evaluation, observations
end

function validate_states(individual::PruneIndividual)
    for node_id in individual.prunable_genes
        for state in individual.states
            if node_id ∉ keys(state.node_values)
                throw(ErrorException("Hidden node ID $node_id not found in state: $state."))
            end
        end
    end
end

function update_individual(
    individual::PruneIndividual, evaluation::Evaluation, observations::Vector{<:Observation}
)
    observations = get_observations(observations, individual.id)
    states = vcat([observation.states for observation in observations]...)
    individual.fitness = get_scaled_fitness(evaluation, individual.id)
    individual.states = states
end

function perform_simulation!(species::PruneSpecies, state::State)
    evaluation, observations = perform_evaluations(species, state)
    for individual in get_individuals_to_evaluate(species)
        update_individual(individual, evaluation, observations)
    end
end

function get_control_prune_species(species::ModesSpecies)
    individuals = [
        PruneIndividual(individual.id, minimize(individual.genotype)) 
        for individual in species.to_prune
    ]
    species = PruneSpecies(species.id, individuals)
    return species
end

function validate_candidates(species, candidates)
    ids = [individual.id for individual in candidates]
    if length(ids) != length(unique(ids))
        throw(ErrorException("Species $(species.id) has $(length(ids)) individuals but" * 
        " $(length(unique(ids))) unique ids."))
    end
end

function update_candidates(species::PruneSpecies{I}) where {I <: PruneIndividual}
    if is_fully_pruned(species)
        return species
    end
    currents = I[]
    candidates = I[]
    for individual in species.currents
        current, candidate = modes_prune(individual)
        push!(currents, current)
        push!(candidates, candidate)
    end
    validate_candidates(species, candidates)
    next_species = PruneSpecies(species.id, currents, candidates, species.pruned)
    return next_species
end

function update_currents(species::PruneSpecies{I}) where {I <: Individual}
    if is_fully_pruned(species)
        return species
    end
    currents = I[]
    pruned = copy(species.pruned)
    for (current, candidate) in zip(species.currents, species.candidates)
        candidate_is_no_worse = candidate.fitness >= current.fitness
        to_keep = candidate_is_no_worse ? candidate : current
        to_push = is_fully_pruned(to_keep) ? pruned : currents
        push!(to_push, to_keep)
    end
    new_species = PruneSpecies(species.id, currents, I[], species.pruned)
    return new_species
end

function perform_modes(species::ModesSpecies, state::State)
    prune_species = PruneSpecies(species)
    if first(get_interactions(state)).id == "Control-A-B"
        return prune_species
    end
    perform_simulation!(prune_species, state)
    while !is_fully_pruned(prune_species)
        prune_species = update_candidates(prune_species)
        perform_simulation!(prune_species, state)
        prune_species = update_currents(prune_species)
    end
    pruned_individuals = prune_species.pruned
    return pruned_individuals
end
