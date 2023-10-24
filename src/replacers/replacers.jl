module Replacers

export Identity, Generational, Truncation

using Random: AbstractRNG
using ..Individuals: Individual
using ..Species: AbstractSpecies
using ..Evaluators: Evaluation

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("identity/identity.jl")
using .Identity: IdentityReplacer

include("generational/generational.jl")
using .Generational: GenerationalReplacer

include("truncation/truncation.jl")
using .Truncation: TruncationReplacer

end
