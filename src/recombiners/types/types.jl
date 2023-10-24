module Types

export CloneRecombiner, IdentityRecombiner

include("clone/clone.jl")
using .Clone: CloneRecombiner

include("identity/identity.jl")
using .Identity: IdentityRecombiner

end