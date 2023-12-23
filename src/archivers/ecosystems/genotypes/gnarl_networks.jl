using ...Genotypes.GnarlNetworks: NodeGene, ConnectionGene
using ...Genotypes.GnarlNetworks: GnarlNetworkGenotype, GnarlNetworkGenotypeCreator

function archive!(
    ::GenotypeArchiver, genotype_group::Group, genotype::GnarlNetworkGenotype
)
    genotype_group["n_input_nodes"] = genotype.n_input_nodes
    genotype_group["n_output_nodes"] = genotype.n_output_nodes

    genotype_group["hidden_node_ids"] = [node.id for node in genotype.hidden_nodes]
    genotype_group["hidden_node_positions"] = [node.position for node in genotype.hidden_nodes]

    genotype_group["connection_ids"] = [conn.id for conn in genotype.connections]
    genotype_group["connection_origins"] = [conn.origin for conn in genotype.connections]
    genotype_group["connection_destinations"] = [conn.destination for conn in genotype.connections]
    genotype_group["connection_weights"] = [conn.weight for conn in genotype.connections]
end

function load_genotype(::GnarlNetworkGenotypeCreator, genotype_group::Group)
    n_input_nodes = genotype_group["n_input_nodes"]
    n_output_nodes = genotype_group["n_output_nodes"]

    neuron_positions = genotype_group["neuron_positions"]
    neuron_ids = genotype_group["neuron_ids"]
    neurons = [
        NodeGene(
            neuron_ids[i], 
            neuron_positions[i]
        ) for i in eachindex(neuron_positions)
    ]

    connection_origins = genotype_group["connection_origins"]
    connection_destinations = genotype_group["connection_destinations"]
    connection_weights = genotype_group["connection_weights"]
    connection_ids = genotype_group["connection_ids"]
    connections = [
        ConnectionGene(
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