module Species

export Abstract, Genotype, andividual, Evaluation

include("abstract/abstract.jl")
using .Abstract: Abstract

include("types/genotype/genotype.jl")
using .Types: Genotype

include("types/individual/individual.jl")
using .Types: Individual

include("types/evaluation/evaluation.jl")
using .Types: Evaluation

end