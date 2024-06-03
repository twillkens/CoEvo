import ....Interfaces: evolve

function evolve(config::CircleExperimentConfiguration)
    state = initialize_state(config)
    evolve!(state)
    return state
end

function evolve(config::CircleExperimentConfiguration, n_generations::Int)
    state = initialize_state(config)
    evolve!(state, n_generations)
    return state
end