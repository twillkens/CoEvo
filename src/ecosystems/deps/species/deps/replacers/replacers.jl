module Replacers

export IdentityReplacer
export GenerationalReplacer
# export TruncationReplacer

include("types/identity.jl")
include("types/generational.jl")
# include("types/truncation.jl")

end