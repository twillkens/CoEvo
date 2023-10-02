module Types

export Ecosystems, Outcomes, Observations, Interactions, Species, Evaluations

include("ecosystems/ecosystems.jl")
using .Ecosystems: Ecosystems

include("outcomes/outcomes.jl")
using .Outcomes: Outcomes

include("observations/observations.jl")
using .Observations: Observations

include("interactions/interactions.jl")
using .Interactions: Interactions

include("species/species.jl")
using .Species: Species

include("evaluations/evaluations.jl")
using .Evaluations: Evaluations

end