module Types

export IdentityReplacer, GenerationalReplacer

include("identity.jl")
using .Identity: IdentityReplacer

include("generational.jl")
using .Generational: GenerationalReplacer

include("truncation.jl")
using .Truncation: TruncationReplacer

end