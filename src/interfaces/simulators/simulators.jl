export simulate, simulate_with_time

using ..Abstract

function simulate(simulator::Simulator, ecosystem::Ecosystem, state::State)
    simulator = typeof(simulator)
    ecosystem = typeof(ecosystem)
    state = typeof(state)    
    error("simulate not implemented for $simulator, $ecosystem, $state")
end

function simulate_with_time(simulator::Simulator, ecosystem::Ecosystem, state::State)
    simulation_time_start = time()
    results = simulate(simulator, ecosystem, state)
    simulation_time = round(time() - simulation_time_start; digits = 3)
    return results, simulation_time
end
