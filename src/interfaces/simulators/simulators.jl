export simulate

using ..Abstract

function simulate(simulator::Simulator, ecosystem::Ecosystem, state::State)
    simulator = typeof(simulator)
    ecosystem = typeof(ecosystem)
    state = typeof(state)    
    error("simulate not implemented for $simulator, $ecosystem, $state")
end