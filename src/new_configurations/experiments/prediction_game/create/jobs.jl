export make_job_creator

using ....Jobs.Basic: BasicJobCreator
using ....MatchMakers.AllVersusAll: AllVersusAllMatchMaker
using ...NewConfigurations.GameConfigurations: make_environment_creator
using ....Interactions.Basic: BasicInteraction
using ...NewConfigurations: get_id

function make_interaction(
    game::GameConfiguration, 
    interaction_setup::BasicInteractionConfiguration, 
)
    interaction = BasicInteraction(
        id = get_id(interaction_setup),
        environment_creator = make_environment_creator(game, interaction_setup),
        species_ids = interaction_setup.species_ids,
        matchmaker = AllVersusAllMatchMaker(),
    )
    return interaction
end

function make_interactions(game::GameConfiguration, topology::TopologyConfiguration)
    interactions = [
        make_interaction(game, interaction)
        for interaction in topology.interactions
    ]
    return interactions
end

function make_job_creator(
    globals::GlobalConfiguration, 
    game::GameConfiguration, 
    topology::TopologyConfiguration, 
)
    job_creator = BasicJobCreator(
        n_workers = get_n_workers(globals), interactions = make_interactions(game, topology)
    )
    return job_creator
end

make_job_creator(config::PredictionGameExperimentConfiguration) = make_job_creator(
    config.globals, config.game, config.topology
)
