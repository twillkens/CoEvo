module Species

export Abstract, Genotype, Individual, Evaluation

include("abstract/abstract.jl")
using .Abstract: Abstract

include("types/genotype/genotype.jl")
using .Genotype: Genotype

include("types/individual/individual.jl")
using .Individual: Individual

include("types/evaluation/evaluation.jl")
using .Evaluation: Evaluation

end