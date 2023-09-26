
"""
    GeneticPrograms

Module providing genotype-phenotype configurations for genetic programs and associated utilities.
"""
module GeneticPrograms

export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration  
export PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration
export BasicGeneticProgramMutator
export Genes, ExpressionNodeGene, Genotypes, Phenotypes, Mutators

# Include the internal components of the module
include("utilities/utilities.jl")
using .Utilities
include("genes/genes.jl")
include("genotypes/genotypes.jl")
include("mutators/mutators.jl")
include("phenotypes/phenotypes.jl")

using .Genes: Genes, ExpressionNodeGene
using .Genotypes: Genotypes, BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration
using .Phenotypes: Phenotypes, PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration
using .Mutators: Mutators, BasicGeneticProgramMutator

# include("archivers/archivers.jl")

# Define any other necessary internal structures and functions below...

end