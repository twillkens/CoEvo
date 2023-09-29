module Results

export Abstract, Basic

include("abstract/abstract.jl")
using .Abstract: Abstract

include("types/basic.jl")
using .Basic: Basic


end