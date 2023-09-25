"""
    Substrates

Module providing substrate configurations and utilities, primarily for genotypes.
"""
module Substrates

export DefaultPhenotypeConfiguration, DefaultMutator
export BasicVectorGenotype, BasicVectorGenotypeConfiguration
export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration
export PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration

include("abstract/abstract.jl")

# Including vector-based genotype configurations
include("types/defaults/defaults.jl")
using .Defaults: DefaultPhenotypeConfiguration, DefaultMutator

include("types/vectors/vectors.jl")
using .Vectors: BasicVectorGenotype, BasicVectorGenotypeConfiguration

include("types/genetic_programs/genetic_programs.jl")
using .GeneticPrograms: BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration
using .GeneticPrograms: PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration


end
