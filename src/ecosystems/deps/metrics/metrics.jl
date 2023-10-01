module Metrics

export Abstract, Ecosystem, Outcome, Observation, Interaction, Species

include("abstract/abstract.jl")
using .Abstract: Abstract

include("types/ecosystem/ecosystem.jl")
using .Ecosystem: Ecosystem

include("types/outcome/outcome.jl")
using .Outcome: Outcome

include("types/observation/observation.jl")
using .Observation: Observation

include("types/interaction/interaction.jl")
using .Interaction: Interaction

include("types/species/species.jl")
using .Species: Species

end