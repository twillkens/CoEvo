using ...Genotypes.GnarlNetworks: NodeGene, ConnectionGene
using ...Genotypes.GnarlNetworks: GnarlNetworkGenotype

function save_genotype!(
    ::BasicArchiver, geno_group::Group, genotype::GnarlNetworkGenotype
)
    geno_group["n_input_nodes"] = genotype.n_input_nodes
    geno_group["n_output_nodes"] = genotype.n_output_nodes

    geno_group["hidden_node_ids"] = [node.id for node in genotype.hidden_nodes]
    geno_group["hidden_node_positions"] = [node.position for node in genotype.hidden_nodes]

    geno_group["connection_ids"] = [conn.id for conn in genotype.connections]
    geno_group["connection_origins"] = [conn.origin for conn in genotype.connections]
    geno_group["connection_destinations"] = [conn.destination for conn in genotype.connections]
    geno_group["connection_weights"] = [conn.weight for conn in genotype.connections]
end
