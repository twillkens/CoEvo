module GnarlNetworks

using JLD2: Group

using .....Ecosystems.Species.Genotypes.GnarlNetworks: GnarlNetworkNodeGene, GnarlNetworkConnectionGene
using .....Ecosystems.Species.Genotypes.GnarlNetworks: GnarlNetworkGenotype
#using .....Ecosystems.Species.Genotypes.GeneticPrograms: GeneticProgramGenotype, ExpressionNodeGene
using ...Basic: BasicArchiver

import ....Archivers.Interfaces: save_genotype!

function save_genotype!(
    ::BasicArchiver, geno_group::Group, geno::GnarlNetworkGenotype
)
    geno_group["n_input_nodes"] = geno.n_input_nodes
    geno_group["n_output_nodes"] = geno.n_output_nodes

    geno_group["hidden_node_ids"] = [node.id for node in geno.hidden_nodes]
    geno_group["hidden_node_positions"] = [node.position for node in geno.hidden_nodes]

    geno_group["connection_ids"] = [conn.id for conn in geno.connections]
    geno_group["connection_origins"] = [conn.origin for conn in geno.connections]
    geno_group["connection_destinations"] = [conn.destination for conn in geno.connections]
    geno_group["connection_weights"] = [conn.weight for conn in geno.connections]
end

end