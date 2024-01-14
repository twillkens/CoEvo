
function Base.show(io::IO, gene::NodeGene)
    println(io, "Node Gene(ID: $(gene.id), Position: $(gene.position))")
end

function Base.show(io::IO, gene::ConnectionGene)
    id, origin, destination, weight = gene.id, gene.origin, gene.destination, gene.weight
    info ="Connection Gene(ID: $id, Origin: $origin, Destination: $destination, Weight: $weight)"
    println(io, info)
end

function Base.show(io::IO, genotype::GnarlNetworkGenotype)
    println(io, "GnarlNetwork Genotype(#Input Nodes: $(genotype.n_input_nodes), #Output Nodes: $(genotype.n_output_nodes))")
    println(io, "Hidden Nodes:")
    for node in genotype.hidden_nodes
        println(io, "   ", node)
    end
    println(io, "Connections:")
    for connection in genotype.connections
        println(io, "   ", connection)
    end
end

function Base.show(io::IO, creator::GnarlNetworkGenotypeCreator)
    println(io, "GnarlNetwork Genotype Creator(#Input Nodes: $(creator.n_input_nodes), #Output Nodes: $(creator.n_output_nodes))")
end
