export ConnectionGene, NodeGene

Base.@kwdef struct NodeGene <: Gene 
    id::Int
    position::Float32
end

function Base.show(io::IO, gene::NodeGene)
    println(io, "Node Gene(ID: $(gene.id), Position: $(gene.position))")
end

Base.:(==)(a::NodeGene, b::NodeGene) = 
    a.id == b.id && 
    a.position == b.position
Base.hash(a::NodeGene, h::UInt) = hash(a.id, h)

Base.@kwdef struct ConnectionGene <: Gene 
    id::Int
    origin::Float32
    destination::Float32
    weight::Float32
end

function Base.show(io::IO, gene::ConnectionGene)
    id, origin, destination, weight = gene.id, gene.origin, gene.destination, gene.weight
    info ="Connection Gene(ID: $id, Origin: $origin, Destination: $destination, Weight: $weight)"
    println(io, info)
end

Base.:(==)(a::ConnectionGene, b::ConnectionGene) = 
    a.id == b.id && 
    a.origin == b.origin &&
    a.destination == b.destination &&
    a.weight == b.weight

Base.hash(a::ConnectionGene, h::UInt) = hash(a.id, h)
