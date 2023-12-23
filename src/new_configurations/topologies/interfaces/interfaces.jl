export get_n_species

get_n_species(topology::TopologyConfiguration) = length(topology.species_ids)
