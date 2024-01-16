export evolve!, convert_to_dict, create_from_dict, archive!
export create_ecosystem_with_time, simulate_with_time, evaluate_with_time

using ..Abstract

evolve!(state::State) = error("evolve! not implemented for $(typeof(state))")

evolve!(state::State, n_generations::Int) = error("evolve! not implemented for $(typeof(state))")

archive!(state::State) = error("archive! not implemented for $(typeof(state))")

function convert_to_dict(state::State, config::Configuration)
    state = typeof(state)
    config = typeof(config)
    error("convert_to_dict not implemented for $state, $config")
end

function convert_to_dict(state::State)
    state = typeof(state)
    error("convert_to_dict not implemented for $state")
end

function create_from_dict(state::StateCreator, dict::Dict, config::Configuration) 
    state = typeof(state)
    dict = typeof(dict)
    config = typeof(config)
    error("convert_from_dict not implemented for $state, $dict, $config")
end

function create_ecosystem_with_time(state::State)
    reproduction_time_start = time()
    ecosystem_creator = state.reproducer.ecosystem_creator
    id = state.configuration.id
    ecosystem = create_ecosystem(ecosystem_creator, id, state)
    reproduction_time = round(time() - reproduction_time_start; digits = 3)
    return ecosystem, reproduction_time
end

function simulate_with_time(
    simulator::Simulator, ecosystem::Ecosystem, state::State
)
    simulation_time_start = time()
    results = simulate(simulator, ecosystem, state)
    simulation_time = round(time() - simulation_time_start; digits = 3)
    return results, simulation_time
end

function evaluate_with_time(
    evaluator::Evaluator, 
    ecosystem::Ecosystem, 
    results::Vector{<:Result}, 
    state::State
)
    evaluation_time_start = time()
    evaluations = evaluate(evaluator, ecosystem, results, state)
    evaluation_time = round(time() - evaluation_time_start; digits = 3)
    return evaluations, evaluation_time
end