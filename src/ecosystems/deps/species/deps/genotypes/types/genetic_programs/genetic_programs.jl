module GeneticPrograms

export Abstract, Utilities, Concrete, Methods

include("abstract/abstract.jl")
using .Abstract: Abstract

include("utilities.jl")
using .Utilities: Utilities

include("concrete/concrete.jl")
using .Concrete: Concrete

include("methods/methods.jl")
using .Methods: Methods

end