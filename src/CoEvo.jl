module CoEvo

export VectorGenoCfg, RandVectorGenoCfg
export SpeciesCfg, DomainCfg, JobCfg, EcoCfg
export NumbersGame

using DataStructures
using Random
using StableRNGs

include("abstract/abstract.jl")
include("utilities/utilities.jl")
include("substrates/substrates.jl")
include("interactions/interactions.jl")
include("species_cfgs/species_cfgs.jl")
include("ecosystems/ecosystems.jl")

using .Substrates.VectorSubstrate: VectorGenoCfg, RandVectorGenoCfg
using .SpeciesConfigurations: SpeciesCfg
using .Interactions: JobCfg, DomainCfg
using .Interactions.Domains.NumbersGame: NumbersGame
using .Ecosystems: EcoCfg

end