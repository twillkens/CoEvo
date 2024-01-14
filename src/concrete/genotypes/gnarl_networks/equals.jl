Base.:(==)(a::NodeGene, b::NodeGene) = 
    a.id == b.id && 
    a.position == b.position

Base.hash(a::NodeGene, h::UInt) = hash(a.id, h)

Base.:(==)(a::ConnectionGene, b::ConnectionGene) = 
    a.id == b.id && 
    a.origin == b.origin &&
    a.destination == b.destination &&
    a.weight == b.weight

Base.hash(a::ConnectionGene, h::UInt) = hash(a.id, h)