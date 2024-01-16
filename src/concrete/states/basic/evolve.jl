using ....Interfaces

function update_ecosystem!(state::BasicEvolutionaryState)
    reproduction_time_start = time()
    update_ecosystem!(
        state.ecosystem, state.reproducer.ecosystem_creator, state.evaluations, state
    )
    state.rng_state_after_reproduction = string(state.rng.state)
    reproduction_time = time() - reproduction_time_start
    state.timers.reproduction_time = round(reproduction_time; digits = 3)
end

function perform_simulation!(state::BasicEvolutionaryState)
    new_results, simulation_time = simulate_with_time(
        state.simulator, state.ecosystem, state
    )
    empty!(state.results)
    append!(state.results, new_results)
    state.timers.simulation_time = simulation_time
end


function perform_evaluation!(state::BasicEvolutionaryState)
    evaluations, evaluation_time = evaluate_with_time(
        state.evaluator, state.ecosystem, state.results, state
    )
    state.timers.evaluation_time = evaluation_time
    empty!(state.evaluations)
    append!(state.evaluations, evaluations)
end

function archive!(state::BasicEvolutionaryState)
    using_archivers = state.checkpoint_interval > 0 
    is_checkpoint = using_archivers && state.generation % state.checkpoint_interval == 0
    if is_checkpoint
        for archiver in state.archivers
            archive!(archiver, state)
        end
    end
end

function check_if_individuals_are_unique(state::State)
    species_ids = [[individual.id for individual in species.population] for species in state.ecosystem.all_species]
    all_ids = vcat(species_ids...)
    unique_ids = Set(all_ids)
    if length(all_ids) != length(unique_ids)
        error("individual ids are not unique")
    end
end


function next_generation!(state::BasicEvolutionaryState)
    state.generation += 1
    update_ecosystem!(state)
    #println("----generation = $(state.generation)----")
    #println("rng_state_after_reproduction = $(state.rng.state)")
    perform_simulation!(state)
    #println("rng_state_after_simulation = $(state.rng.state)")
    perform_evaluation!(state)
    #println("rng_state_after_evaluation = $(state.rng.state)")
    archive!(state)
end

function evolve!(state::BasicEvolutionaryState, n_generations::Int)
    for _ in 1:n_generations
        next_generation!(state)
        if state.generation % 25 == 0
            GC.gc()
        end
    end
end

function evolve!(state::BasicEvolutionaryState) 
    while state.generation < state.configuration.n_generations
        next_generation!(state)
        if state.generation % 25 == 0
            GC.gc()
        end
    end
end