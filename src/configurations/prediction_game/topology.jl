export Topology, InteractionSetup, BasicTopology, load_topology, get_topology
export get_id

abstract type Topology end

function get_n_species(topology::Topology)
    throw(ErrorException("get_n_species not implemented for topology of type $(typeof(topology))"))
end

Base.@kwdef struct InteractionSetup
    species_ids::Vector{String}
    domain::String
end

function get_id(interaction_setup::InteractionSetup)
    domain = interaction_setup.domain
    species_ids = interaction_setup.species_ids
    id = join([domain, species_ids...], "-")
    return id
end

function archive!(interaction_setup::InteractionSetup, file::File)
    id = get_id(interaction_setup)
    base_path = "configuration/topology/interactions/$id"
    file["$base_path/species_ids"] = interaction_setup.species_ids
    file["$base_path/domain"] = interaction_setup.domain
end

Base.@kwdef struct BasicTopology <: Topology
    id::String
    species_ids::Vector{String}
    cohorts::Vector{String}
    interactions::Vector{InteractionSetup}
end

function get_n_species(topology::BasicTopology)
    return length(topology.species_ids)
end

get_species_ids(topology::BasicTopology) = topology.species_ids

function archive!(topology::BasicTopology, file::File)
    base_path = "configuration/topology"
    file["$base_path/id"] = topology.id
    file["$base_path/species_ids"] = topology.species_ids
    file["$base_path/cohorts"] = topology.cohorts
    [archive!(interaction_setup, file) for interaction_setup in topology.interactions]
end

function load_topology(file::File)
    base_path = "configuration/topology"
    id = read(file["$base_path/id"])
    species_ids = read(file["$base_path/species_ids"])
    cohorts = read(file["$base_path/cohorts"])
    interactions = [
        InteractionSetup(
            species_ids = read(file["$base_path/interactions/$interaction_id/species_ids"]),
            domain = read(file["$base_path/interactions/$interaction_id/domain"]),
        )
        for interaction_id in keys(file["$base_path/interactions"])
    ]
    topology = BasicTopology(
        id = id,
        species_ids = species_ids,
        cohorts = cohorts,
        interactions = interactions,
    )
    return topology
end

function get_id(topology::Topology)
    return topology.id
end


const TOPOLOGIES = Dict(
    "two_control" => BasicTopology(
        id = "two_control",
        species_ids = ["A", "B"],
        cohorts = ["population", "children"],
        interactions = [
            InteractionSetup(
                species_ids = ["A", "B"],
                domain = "Control",
            ),
        ],
    ),
    "two_cooperative" => BasicTopology(
        id = "two_cooperative",
        species_ids = ["H", "M"],
        cohorts = ["population", "children"],
        interactions = [
            InteractionSetup(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
        ],
    ),
    "two_competitive" => BasicTopology(
        id = "two_competitive",
        species_ids = ["P", "H"],
        cohorts = ["population", "children"],
        interactions = [
            InteractionSetup(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_mixed" => BasicTopology(
        id = "three_mixed",
        species_ids = ["H", "M", "P"],
        cohorts = ["population", "children"],
        interactions = [
            InteractionSetup(
                species_ids = ["H", "M"],
                domain = "Affinitive",
            ),
            InteractionSetup(
                species_ids = ["M", "P"],
                domain = "Avoidant",
            ),
            InteractionSetup(
                species_ids = ["P", "H"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_cooperative" => BasicTopology(
        id = "three_cooperative",
        species_ids = ["A", "B", "C"],
        cohorts = ["population", "children"],
        interactions = [
            InteractionSetup(
                species_ids = ["A", "B"],
                domain = "Affinitive",
            ),
            InteractionSetup(
                species_ids = ["A", "C"],
                domain = "Affinitive",
            ),
            InteractionSetup(
                species_ids = ["B", "C"],
                domain = "Avoidant",
            ),
        ],
    ),
    "three_competitive" => BasicTopology(
        id = "three_competitive",
        species_ids = ["X", "Y", "Z"],
        cohorts = ["population", "children"],
        interactions = [
            InteractionSetup(
                species_ids = ["X", "Y"],
                domain = "PredatorPrey",
            ),
            InteractionSetup(
                species_ids = ["Y", "Z"],
                domain = "PredatorPrey",
            ),
            InteractionSetup(
                species_ids = ["Z", "X"],
                domain = "PredatorPrey",
            ),
        ],
    ),
    "three_control" => BasicTopology(
        id = "three_control",
        species_ids = ["X", "Y", "Z"],
        cohorts = ["population", "children"],
        interactions = [
            InteractionSetup(
                species_ids = ["X", "Y"],
                domain = "Control",
            ),
            InteractionSetup(
                species_ids = ["Y", "Z"],
                domain = "Control",
            ),
            InteractionSetup(
                species_ids = ["Z", "X"],
                domain = "Control",
            ),
        ],
    ),
)

function get_topology(id::String)
    if !haskey(TOPOLOGIES, id)
        error("Topology with id $id not found.")
    end
    topology = TOPOLOGIES[id]
    return topology
end