module Genes

export GnarlNetworkConnectionGene, GnarlNetworkNodeGene

using ....Species.Genotypes.Abstract: Gene

struct GnarlNetworkNodeGene <: Gene 
    id::Int
    position::Float32
end

Base.:(==)(a::GnarlNetworkNodeGene, b::GnarlNetworkNodeGene) = a.id == b.id
Base.hash(a::GnarlNetworkNodeGene, h::UInt) = hash(a.id, h)


struct GnarlNetworkConnectionGene <: Gene 
    id::Int
    origin::Float32
    destination::Float32
    weight::Float32
end

Base.:(==)(a::GnarlNetworkConnectionGene, b::GnarlNetworkConnectionGene) = a.id == b.id
Base.hash(a::GnarlNetworkConnectionGene, h::UInt) = hash(a.id, h)

end