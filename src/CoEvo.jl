module CoEvo

using DataStructures
using Random
using StableRNGs

include("abstract/abstract.jl")
include("utilities/utilities.jl")
include("substrates/substrates.jl")
include("interactions/interactions.jl")
include("species/species.jl")
include("ecosystems/ecosystems.jl")

using .Substrates.VectorSubstrate: VectorGenoCfg, RandVectorGenoCfg
export VectorGenoCfg, RandVectorGenoCfg


end