export Topology, InteractionSetup, BasicTopology, load_topology, get_topology
export get_id

abstract type Topology end

function get_n_species(topology::Topology)
    throw(ErrorException("get_n_species not implemented for topology of type $(typeof(topology))"))
end

abstract type InteractionSetup end

Base.@kwdef struct BasicInteractionSetup
    species_ids::Vector{String}
    domain::String
end

function get_id(interaction_setup::BasicInteractionSetup)
    domain = interaction_setup.domain
    species_ids = interaction_setup.species_ids
    id = join([domain, species_ids...], "-")
    return id
end

function archive!(interaction_setup::BasicInteractionSetup, file::File)
    id = get_id(interaction_setup)
    base_path = "configuration/topology/interactions/$id"
    file["$base_path/species_ids"] = interaction_setup.species_ids
    file["$base_path/domain"] = interaction_setup.domain
end

Base.@kwdef struct BasicTopology <: Topology
    id::String
    species_ids::Vector{String}
    cohorts::Vector{String}
    interaction_setups::Vector{BasicInteractionSetup}
end

Base.@kwdef struct ModesTopology <: Topology
    id::String
    basic_topology::BasicTopology
    modes_interval::Int
    adaptive_archive_length::Int
    elites_archive_length::Int
end

function get_n_species(topology::BasicTopology)
    return length(topology.species_ids)
end

get_species_ids(topology::BasicTopology) = topology.species_ids

get_species_ids(topology::ModesTopology) = get_species_ids(topology.basic_topology)

function archive!(topology::BasicTopology, file::File)
    base_path = "configuration/topology"
    file["$base_path/id"] = topology.id
    file["$base_path/species_ids"] = topology.species_ids
    file["$base_path/cohorts"] = topology.cohorts
    [archive!(interaction_setup, file) for interaction_setup in topology.interaction_setups]
end

function archive!(topology::ModesTopology, file::File)
    archive!(topology.basic_topology, file)
    base_path = "configuration/topology"
    file["$base_path/modes_interval"] = topology.modes_interval
end

function load_topology(file::File)
    base_path = "configuration/topology"
    id = read(file["$base_path/id"])
    species_ids = read(file["$base_path/species_ids"])
    cohorts = read(file["$base_path/cohorts"])
    interaction_setups = [
        BasicInteractionSetup(
            species_ids = read(file["$base_path/interactions/$interaction_id/species_ids"]),
            domain = read(file["$base_path/interactions/$interaction_id/domain"]),
        )
        for interaction_id in keys(file["$base_path/interactions"])
    ]
    topology = BasicTopology(
        id = id,
        species_ids = species_ids,
        cohorts = cohorts,
        interaction_setups = interaction_setups,
    )
    if haskey(file, "$base_path/modes_interval")
        modes_interval = read(file["$base_path/modes_interval"])
        topology = ModesTopology(
            id = id,
            basic_topology = topology,
            modes_interval = modes_interval,
        )
    end
    return topology
end

function get_id(topology::Topology)
    return topology.id
end


const BASIC_TOPOLOGIES = Dict(
    "two_control" => BasicTopology(
        id = "two_control",
        species_ids = ["A", "B"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["A", "B"],
                domain = "Control",
            ),
        ],
    ),
    "two_cooperative" => BasicTopology(
        id = "two_cooperative",
        species_ids = ["H", "M"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
        ],
    ),
    "two_competitive" => BasicTopology(
        id = "two_competitive",
        species_ids = ["P", "H"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "two_competitive_adaptive" => BasicTopology(
        id = "two_competitive_adaptive",
        species_ids = ["P", "H"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_mixed" => BasicTopology(
        id = "three_mixed",
        species_ids = ["H", "M", "P"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
            BasicInteractionSetup(
                species_ids = ["M", "P"],
                domain = "Avoidant",
            ),
            BasicInteractionSetup(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_cooperative" => BasicTopology(
        id = "three_cooperative",
        species_ids = ["A", "B", "C"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["A", "B"],
                domain = "Affinitive",
            ),
            BasicInteractionSetup(
                species_ids = ["A", "C"],
                domain = "Affinitive",
            ),
            BasicInteractionSetup(
                species_ids = ["B", "C"],
                domain = "Avoidant",
            ),
        ],
    ),
    "three_competitive" => BasicTopology(
        id = "three_competitive",
        species_ids = ["X", "Y", "Z"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["X", "Y"],
                domain = "PredatorPrey",
            ),
            BasicInteractionSetup(
                species_ids = ["Y", "Z"],
                domain = "PredatorPrey",
            ),
            BasicInteractionSetup(
                species_ids = ["Z", "X"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_control" => BasicTopology(
        id = "three_control",
        species_ids = ["X", "Y", "Z"],
        cohorts = ["population", "children"],
        interaction_setups = [
            BasicInteractionSetup(
                species_ids = ["X", "Y"],
                domain = "Control",
            ),
            BasicInteractionSetup(
                species_ids = ["Y", "Z"],
                domain = "Control",
            ),
            BasicInteractionSetup(
                species_ids = ["Z", "X"],
                domain = "Control",
            ),
        ],
    ),
)

function get_topology(
    id::String; 
    adaptive_archive_length::Int = 0, 
    elites_archive_length::Int = 0, 
    modes_interval::Int = 0,
    kwargs...
)
    if !haskey(BASIC_TOPOLOGIES, id)
        error("Topology with id $id not found.")
    end
    basic_topology = BASIC_TOPOLOGIES[id]
    if modes_interval == 0
        println("Using basic topology")
        return basic_topology
    else
        println("Using modes topology")
        topology = ModesTopology(
            id = id,
            basic_topology = basic_topology,
            modes_interval = modes_interval,
            adaptive_archive_length = adaptive_archive_length,
            elites_archive_length = elites_archive_length,
        )
        return topology
    end
end