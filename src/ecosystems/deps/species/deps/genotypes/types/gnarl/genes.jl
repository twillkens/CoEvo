module Genes

export GnarlNetworkConnectionGene, GnarlNetworkNodeGene

using ....Species.Genotypes.Abstract: Gene

struct GnarlNetworkNodeGene <: Gene 
    id::Int
    position::Float32
end

function Base.show(io::IO, gene::GnarlNetworkNodeGene)
    println(io, "Node Gene(ID: $(gene.id), Position: $(gene.position))")
end


Base.:(==)(a::GnarlNetworkNodeGene, b::GnarlNetworkNodeGene) = a.id == b.id
Base.hash(a::GnarlNetworkNodeGene, h::UInt) = hash(a.id, h)

Base.@kwdef struct GnarlNetworkConnectionGene <: Gene 
    id::Int
    origin::Float32
    destination::Float32
    weight::Float32
end

function Base.show(io::IO, gene::GnarlNetworkConnectionGene)
    println(io, "Connection Gene(ID: $(gene.id), Origin: $(gene.origin), Destination: $(gene.destination), Weight: $(gene.weight))")
end

Base.:(==)(a::GnarlNetworkConnectionGene, b::GnarlNetworkConnectionGene) = a.id == b.id
Base.hash(a::GnarlNetworkConnectionGene, h::UInt) = hash(a.id, h)


end