module GnarlNetworks

export GnarlNetworkGenotypeLoader

using JLD2: Group
using ....Ecosystems.Species.Genotypes.GnarlNetworks: GnarlNetworkNodeGene, GnarlNetworkConnectionGene, GnarlNetworkGenotype 
using ...Loaders.Abstract: Loader

import ...Loaders.Interfaces: load_genotype

struct GnarlNetworkGenotypeLoader <: Loader end

function load_genotype(::GnarlNetworkGenotypeLoader, geno_group::Group)
    n_input_nodes = geno_group["n_input_nodes"]
    n_output_nodes = geno_group["n_output_nodes"]

    neuron_positions = geno_group["neuron_positions"]
    neuron_ids = geno_group["neuron_ids"]
    neurons = [
        GnarlNetworkNodeGene(
            neuron_ids[i], 
            neuron_positions[i]
        ) for i in eachindex(neuron_positions)
    ]

    connection_origins = geno_group["connection_origins"]
    connection_destinations = geno_group["connection_destinations"]
    connection_weights = geno_group["connection_weights"]
    connection_ids = geno_group["connection_ids"]
    connections = [
        GnarlNetworkConnectionGene(
            connection_ids[i], 
            connection_origins[i], 
            connection_destinations[i], 
            connection_weights[i]
        ) for i in eachindex(connection_origins)
    ]
    genotype = GnarlNetworkGenotype(
        n_input_nodes, 
        n_output_nodes, 
        neurons, 
        connections
    )
    return genotype
end

end