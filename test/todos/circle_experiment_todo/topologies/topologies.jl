Base.@kwdef struct InteractionConfig
    species_ids::Vector{String}
    domain::String
end

function get_id(interaction_setup::InteractionConfig)
    domain = interaction_setup.domain
    species_ids = interaction_setup.species_ids
    id = join([domain, species_ids...], "-")
    return id
end

Base.@kwdef struct TopologyConfig
    species_ids::Vector{String}
    interactions::Vector{InteractionConfig}
end

const PREDICTION_GAME_TOPOLOGIES = Dict(
    "two_control" => TopologyConfig(
        species_ids = ["A", "B"],
        interactions = [
            InteractionConfig(
                species_ids = ["A", "B"],
                domain = "Control",
            ),
        ],
    ),
    "two_cooperative" => TopologyConfig(
        species_ids = ["H", "M"],
        interactions = [
            InteractionConfig(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
        ],
    ),
    "two_competitive" => TopologyConfig(
        species_ids = ["P", "H"],
        interactions = [
            InteractionConfig(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "two_competitive_adaptive" => TopologyConfig(
        species_ids = ["P", "H"],
        interactions = [
            InteractionConfig(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_mixed" => TopologyConfig(
        species_ids = ["H", "M", "P"],
        interactions = [
            InteractionConfig(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
            InteractionConfig(
                species_ids = ["M", "P"],
                domain = "Avoidant",
            ),
            InteractionConfig(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_cooperative" => TopologyConfig(
        species_ids = ["A", "B", "C"],
        interactions = [
            InteractionConfig(
                species_ids = ["A", "B"],
                domain = "Affinitive",
            ),
            InteractionConfig(
                species_ids = ["A", "C"],
                domain = "Affinitive",
            ),
            InteractionConfig(
                species_ids = ["B", "C"],
                domain = "Avoidant",
            ),
        ],
    ),
    "three_competitive" => TopologyConfig(
        species_ids = ["X", "Y", "Z"],
        interactions = [
            InteractionConfig(
                species_ids = ["X", "Y"],
                domain = "PredatorPrey",
            ),
            InteractionConfig(
                species_ids = ["Y", "Z"],
                domain = "PredatorPrey",
            ),
            InteractionConfig(
                species_ids = ["Z", "X"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_control" => TopologyConfig(
        species_ids = ["X", "Y", "Z"],
        interactions = [
            InteractionConfig(
                species_ids = ["X", "Y"],
                domain = "Control",
            ),
            InteractionConfig(
                species_ids = ["Y", "Z"],
                domain = "Control",
            ),
            InteractionConfig(
                species_ids = ["Z", "X"],
                domain = "Control",
            ),
        ],
    ),
)
