module Concrete

export BasicArchiver

include("basic/basic.jl")
using .Basic: BasicArchiver

include("basic/genotypes/genotypes.jl")
using .Genotypes: Genotypes

end