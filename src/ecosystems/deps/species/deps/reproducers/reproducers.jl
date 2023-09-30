module Reproducers

export Abstract, Replacers, Selectors, Recombiners, Interfaces

include("abstract/abstract.jl")
using .Abstract: Abstract

include("deps/replacers/replacers.jl")
using .Replacers: Replacers

include("deps/selectors/selectors.jl")
using .Selectors: Selectors

include("deps/recombiners/recombiners.jl")
using .Recombiners: Recombiners

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("types/basic.jl")

end