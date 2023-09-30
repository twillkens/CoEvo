module Types

export IdentityReplacer, GenerationalReplacer

include("identity.jl")
using .Identity: IdentityReplacer

include("generational.jl")
using .Generational: GenerationalReplacer

# TODO: Implement tournament selection
# include("tournament.jl")

# TODO: Implement truncation selection
# include("truncation.jl")

end