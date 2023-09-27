module Reproducers

export BasicReproducer

include("abstract/abstract.jl")
using .Abstract

include("deps/replacers/replacers.jl")
using .Replacers

include("deps/selectors/selectors.jl")
using .Selectors

include("deps/recombiners/recombiners.jl")
using .Recombiners

include("types/basic.jl")

end