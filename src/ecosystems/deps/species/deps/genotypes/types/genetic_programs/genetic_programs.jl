
"""
    GeneticPrograms

Module providing genotype-phenotype configurations for genetic programs and associated utilities.
"""
module GeneticPrograms

export BasicGeneticProgramGenotype  # Export the genotype type
export GeneticProgramConfiguration  # Export the configuration type

# Import necessary packages
using Random
using StatsBase
using ..Common
using JLD2

# Include the internal components of the module
include("utilities/utilities.jl")
include("geno.jl")
include("mutator.jl")
include("pheno.jl")
include("graphpheno.jl")
include("archiver.jl")

# Define any other necessary internal structures and functions below...

end