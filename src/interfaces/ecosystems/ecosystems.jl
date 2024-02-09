export create_ecosystem, update_ecosystem!, convert_to_dict, create_from_dict
export create_ecosystem_with_time, update_ecosystem_with_time!

using ..Abstract

function create_ecosystem(
    ecosystem_creator::EcosystemCreator, reproducers::Vector{Reproducer}, state::State
)
    ecosystem_creator = typeof(ecosystem_creator)
    reproducers = typeof(reproducers)
    state = typeof(state)
    error("create_ecosystem not implemented for $ecosystem_creator, $reproducers, $state")
end

function create_ecosystem_with_time(
    ecosystem_creator::EcosystemCreator, reproducers::Vector{Reproducer}, state::State
)
    reproduction_time_start = time()
    ecosystem = create_ecosystem(ecosystem_creator, reproducers, state)
    reproduction_time = round(time() - reproduction_time_start; digits = 3)
    return ecosystem, reproduction_time
end

function update_ecosystem!(
    ecosystem::Ecosystem, 
    ecosystem_creator::EcosystemCreator, 
    evaluations::Vector{Evaluation},
    reproducers::Vector{Reproducer},
    state::State
)
    ecosystem = typeof(ecosystem)
    ecosystem_creator = typeof(ecosystem_creator)
    reproducers = typeof(reproducers)
    evaluations = typeof(evaluations)
    state = typeof(state)
    error("`update_ecosystem!` not implemented for $ecosystem, $ecosystem_creator, $evaluations, $state")
end

function update_ecosystem_with_time!(
    ecosystem::Ecosystem, 
    ecosystem_creator::EcosystemCreator, 
    evaluations::Vector{Evaluation},
    reproducers::Vector{Reproducer},
    state::State
)
    reproduction_time_start = time()
    update_ecosystem!(ecosystem, ecosystem_creator, evaluations, reproducers, state)
    reproduction_time = round(time() - reproduction_time_start; digits = 3)
    return reproduction_time
end

function convert_to_dict(ecosystem::Ecosystem)
    error("convert_to_dict not implemented for $ecosystem")
end

function create_from_dict(ecosystem_creator::EcosystemCreator, dict::Dict, state::State)
    ecosystem_creator = typeof(ecosystem_creator)
    dict = typeof(dict)
    state = typeof(state)
    error("create_from_dict not implemented for $ecosystem_creator, $dict, $state")
end