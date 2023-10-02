module Species

export Abstract, Types

include("abstract/abstract.jl")
using .Abstract: Abstract

include("types/types.jl")
using .Types: Types

#include("types/genotype/genotype.jl")
#using .Genotype: Genotype
#
#include("types/individual/individual.jl")
#using .Individual: Individual
#
#include("types/evaluation/evaluation.jl")
#using .Evaluation: Evaluation

end