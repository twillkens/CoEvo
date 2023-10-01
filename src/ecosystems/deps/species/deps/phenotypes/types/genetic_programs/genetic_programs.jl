module GeneticPrograms

export GeneticProgramPhenotype

include("nodes.jl")
using .Nodes: Nodes

include("phenotypes.jl")
using .Phenotypes: GeneticProgramPhenotype

end