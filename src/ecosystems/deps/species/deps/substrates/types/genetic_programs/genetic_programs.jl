
"""
    GeneticPrograms

Module providing genotype-phenotype configurations for genetic programs and associated utilities.
"""
module GeneticPrograms

export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration  
export PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration
export BasicGeneticProgramMutator

# Include the internal components of the module
include("utilities/utilities.jl")
using .Utilities
include("genes/genes.jl")
include("genotypes/genotypes.jl")
include("mutators/mutators.jl")
include("phenotypes/phenotypes.jl")

# include("archivers/archivers.jl")

# Define any other necessary internal structures and functions below...

end