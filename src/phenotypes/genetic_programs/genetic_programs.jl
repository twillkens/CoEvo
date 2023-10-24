module GeneticPrograms

import ..Phenotypes: act!, create_phenotype, reset!

using ...Genotypes.GeneticPrograms: GeneticProgramGenotype, if_less_then_else, get_node
using ..Phenotypes: PhenotypeCreator, Phenotype

include("nodes.jl")

include("phenotype.jl")

end