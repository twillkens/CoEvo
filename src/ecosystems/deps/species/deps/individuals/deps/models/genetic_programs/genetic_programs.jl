
"""
    GeneticPrograms

Module providing genotype-phenotype configurations for genetic programs and associated utilities.
"""
module GeneticPrograms

export Genes
export Genotypes
export Phenotypes
export Mutators

# Include the internal components of the module
include("utilities/utilities.jl")

include("genes/genes.jl")
include("genotypes/genotypes.jl")
include("mutators/mutators.jl")
include("phenotypes/phenotypes.jl")

using .Genes: Genes
using .Genotypes: Genotypes
using .Phenotypes: Phenotypes
using .Mutators: Mutators

# include("archivers/archivers.jl")

# Define any other necessary internal structures and functions below...

end