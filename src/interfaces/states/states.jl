export evolve!, convert_to_dict, create_from_dict, archive!
export create_ecosystem_with_time, evaluate_with_time

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

