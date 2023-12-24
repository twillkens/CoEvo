export add_elites_to_archive

function add_elites_to_archive(
    species::ModesSpecies, n_elites::Int, candidates::Vector{<:Individual}
)
    elites = copy(get_elites(species))
    for candidate in candidates
        if candidate.id in Set([individual.id for individual in elites])
            elites = filter!(individual -> individual.id != candidate.id, elites)
        end
        push!(elites, candidate)
    end
    while length(elites) > n_elites
        # eject the first elements to maintain size
        deleteat!(elites, 1)
    end
    new_current_state = ModesCheckpointState(
        population = get_population(species), 
        pruned = get_pruned(species), 
        pruned_fitnesses = get_pruned_fitnesses(species),
        elites = elites
    )
    new_species = ModesSpecies(
        id = species.id,
        current_state = new_current_state,
        previous_state = species.previous_state,
        all_previous_pruned = species.all_previous_pruned,
    )
    return new_species
end