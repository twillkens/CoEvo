export get_topology, load_topology, PREDICTION_GAME_TOPOLOGIES

using ...TopologyConfigurations.Basic: BasicTopologyConfiguration, BasicInteractionConfiguration
using ...TopologyConfigurations.Modes: ModesTopologyConfiguration

const PREDICTION_GAME_TOPOLOGIES = Dict(
    "two_control" => BasicTopologyConfiguration(
        id = "two_control",
        species_ids = ["A", "B"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["A", "B"],
                domain = "Control",
            ),
        ],
    ),
    "two_cooperative" => BasicTopologyConfiguration(
        id = "two_cooperative",
        species_ids = ["H", "M"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
        ],
    ),
    "two_competitive" => BasicTopologyConfiguration(
        id = "two_competitive",
        species_ids = ["P", "H"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "two_competitive_adaptive" => BasicTopologyConfiguration(
        id = "two_competitive_adaptive",
        species_ids = ["P", "H"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_mixed" => BasicTopologyConfiguration(
        id = "three_mixed",
        species_ids = ["H", "M", "P"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
            BasicInteractionConfiguration(
                species_ids = ["M", "P"],
                domain = "Avoidant",
            ),
            BasicInteractionConfiguration(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_cooperative" => BasicTopologyConfiguration(
        id = "three_cooperative",
        species_ids = ["A", "B", "C"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["A", "B"],
                domain = "Affinitive",
            ),
            BasicInteractionConfiguration(
                species_ids = ["A", "C"],
                domain = "Affinitive",
            ),
            BasicInteractionConfiguration(
                species_ids = ["B", "C"],
                domain = "Avoidant",
            ),
        ],
    ),
    "three_competitive" => BasicTopologyConfiguration(
        id = "three_competitive",
        species_ids = ["X", "Y", "Z"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["X", "Y"],
                domain = "PredatorPrey",
            ),
            BasicInteractionConfiguration(
                species_ids = ["Y", "Z"],
                domain = "PredatorPrey",
            ),
            BasicInteractionConfiguration(
                species_ids = ["Z", "X"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_control" => BasicTopologyConfiguration(
        id = "three_control",
        species_ids = ["X", "Y", "Z"],
        interactions = [
            BasicInteractionConfiguration(
                species_ids = ["X", "Y"],
                domain = "Control",
            ),
            BasicInteractionConfiguration(
                species_ids = ["Y", "Z"],
                domain = "Control",
            ),
            BasicInteractionConfiguration(
                species_ids = ["Z", "X"],
                domain = "Control",
            ),
        ],
    ),
)

function get_topology(
    id::String; n_elites::Int = 50, modes_interval::Int = 50, kwargs...
)
    if !haskey(PREDICTION_GAME_TOPOLOGIES, id)
        error("Topology with id $id not found.")
    end
    basic_topology = PREDICTION_GAME_TOPOLOGIES[id]
    #if modes_interval == 0
    #    println("Using basic topology")
    #    return basic_topology
    #else
        println("Using modes topology")
        topology = ModesTopologyConfiguration(
            id = id,
            species_ids = basic_topology.species_ids,
            interactions = basic_topology.interactions,
            modes_interval = modes_interval,
            n_elites = n_elites,
        )
        return topology
    #end
end

function load_topology(file::File)
    base_path = "configuration/topology"
    id = read(file["$base_path/id"])
    species_ids = read(file["$base_path/species_ids"])
    interactions = [
        BasicInteractionConfiguration(
            species_ids = read(file["$base_path/interactions/$interaction_id/species_ids"]),
            domain = read(file["$base_path/interactions/$interaction_id/domain"]),
        )
        for interaction_id in keys(file["$base_path/interactions"])
    ]
    topology = BasicTopologyConfiguration(
        id = id,
        species_ids = species_ids,
        interactions = interactions,
    )
    if haskey(file, "$base_path/modes_interval")
        modes_interval = read(file["$base_path/modes_interval"])
        n_elites = read(file["$base_path/n_elites"])
        topology = ModesTopologyConfiguration(
            id = id,
            species_ids = species_ids,
            interactions = interactions,
            modes_interval = modes_interval,
            n_elites = n_elites
        )
    end
    return topology
end