module Criteria

export Abstract, Types

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/types.jl")
using .Types: Types

end