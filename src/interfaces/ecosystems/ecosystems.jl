export create_ecosystem, update_ecosystem!, convert_to_dict, create_from_dict

using ..Abstract

function create_ecosystem(ecosystem_creator::EcosystemCreator, id::Int, state::State)
    ecosystem_creator = typeof(ecosystem_creator)
    id = typeof(id)
    state = typeof(state)
    error("`create_environment` not implemented for $ecosystem_creator, $id, $state")
end

function update_ecosystem!(
    ecosystem::Ecosystem, 
    ecosystem_creator::EcosystemCreator, 
    evaluations::Vector{Evaluation},
    state::State
)
    ecosystem = typeof(ecosystem)
    ecosystem_creator = typeof(ecosystem_creator)
    evaluations = typeof(evaluations)
    state = typeof(state)
    error("`update_ecosystem!` not implemented for $ecosystem, $ecosystem_creator, $evaluations, $state")
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