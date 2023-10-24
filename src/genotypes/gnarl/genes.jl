export GnarlNetworkConnectionGene, GnarlNetworkNodeGene

Base.@kwdef struct GnarlNetworkNodeGene <: Gene 
    id::Int
    position::Float32
end

function Base.show(io::IO, gene::GnarlNetworkNodeGene)
    println(io, "Node Gene(ID: $(gene.id), Position: $(gene.position))")
end

Base.:(==)(a::GnarlNetworkNodeGene, b::GnarlNetworkNodeGene) = 
    a.id == b.id && 
    a.position == b.position
Base.hash(a::GnarlNetworkNodeGene, h::UInt) = hash(a.id, h)

Base.@kwdef struct GnarlNetworkConnectionGene <: Gene 
    id::Int
    origin::Float32
    destination::Float32
    weight::Float32
end

function Base.show(io::IO, gene::GnarlNetworkConnectionGene)
    id, origin, destination, weight = gene.id, gene.origin, gene.destination, gene.weight
    info ="Connection Gene(ID: $id, Origin: $origin, Destination: $destination, Weight: $weight)"
    println(io, info)
end

Base.:(==)(a::GnarlNetworkConnectionGene, b::GnarlNetworkConnectionGene) = 
    a.id == b.id && 
    a.origin == b.origin &&
    a.destination == b.destination &&
    a.weight == b.weight

Base.hash(a::GnarlNetworkConnectionGene, h::UInt) = hash(a.id, h)
