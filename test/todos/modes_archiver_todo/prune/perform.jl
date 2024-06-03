
using ....Abstract
using ....Interfaces
using ....Evaluators.ScalarFitness: ScIlarFitnessEvaluator


function update_individual(
    individual::PruneIndividual, evaluation::Evaluation, observations::Vector{<:Observation};
    assign_full_fitness::Bool = false
)
    observations = get_observations(observations, individual.id)
    states = vcat([observation.states for observation in observations]...)
    individual.fitness = get_scaled_fitness(evaluation, individual.id)
    if assign_full_fitness
        individual.full_fitness = individual.fitness
    end
    individual.states = states
end

function perform_simulation!(species::PruneSpecies, state::State; assign_full_fitness::Bool)
    evaluation, observations = perform_evaluations(species, state)
    for individual in get_individuals_to_evaluate(species)
        update_individual(
            individual, evaluation, observations; assign_full_fitness = assign_full_fitness
        )
        #println("individual.id = $(individual.id), fitness = $(individual.fitness), full_fitness = $(individual.full_fitness)")
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
    #println("---update_candidates")
    #println("length currents: $(length(currents))")
    #println("length candidates: $(length(candidates))")
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
    #println("---update_currents")
    #println("length currents: $(length(currents))")
    #println("length pruned: $(length(pruned))")
    new_species = PruneSpecies(species.id, currents, I[], pruned)
    return new_species
end

function PruneSpecies(species::AbstractSpecies, state::State)
    prune_species, dummy_species = PruneSpecies(species)
    length_start = length(prune_species.currents) + length(prune_species.pruned)

    perform_simulation!(dummy_species, state; assign_full_fitness = true)
    if occursin(r"Control", first(state.simulator.interactions).id)
        pruned_individuals = [prune_species.currents ; prune_species.pruned]
        return pruned_individuals
    elseif is_fully_pruned(prune_species)
        pruned_individuals = prune_species.pruned
        return prune_species.pruned
    end
    while !is_fully_pruned(prune_species)
        prune_species = update_candidates(prune_species)
        perform_simulation!(prune_species, state; assign_full_fitness = false)
        prune_species = update_currents(prune_species)
    end
    pruned_individuals = prune_species.pruned
    if length(pruned_individuals) == 0
        println("species =  $prune_species")
        throw(ErrorException("No individuals were pruned."))
    end
    if length(pruned_individuals) != length_start
        println("prune_species = $prune_species")
        println("pruned_individuals_after: $pruned_individuals")
        throw(ErrorException("length pruned_individuals != length_start"))
    end
    return pruned_individuals
end
