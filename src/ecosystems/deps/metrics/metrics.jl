module Metrics

include("abstract/abstract.jl")
using .Abstract: Abstract

include("types/ecosystem/ecosystem.jl")
using .Ecosystem: Ecosystem

include("types/observation/observation.jl")
using .Observation: Observation

include("types/interaction/interaction.jl")
using .Interaction: Interaction

include("types/species/species.jl")
using .Species: Species

end