"""
    Module Substrates

Provides substrate configurations and utilities for defining genotype structures and related functionalities.

# Structure

- **Exported Types**:
    - `DefaultPhenotypeConfiguration`: Basic configuration type for phenotypes.
    - `DefaultMutator`: Standard mutation configuration for genotypes.
    - `BasicVectorGenotype`: Genotype representation as a vector.
    - `BasicVectorGenotypeConfiguration`: Configuration for the `BasicVectorGenotype`.
    - `BasicGeneticProgramGenotype`: Representation of genotypes as genetic programs.
    - `BasicGeneticProgramGenotypeConfiguration`: Configuration for the `BasicGeneticProgramGenotype`.
    - `PlayerPianoPhenotype`: Specialized phenotype representation.
    - `PlayerPianoPhenotypeConfiguration`: Configuration for the `PlayerPianoPhenotype`.
    
- **Sections**:
    - Abstract: Core abstract types and interfaces for the substrates.
    - Defaults: Default configurations and utilities for phenotypes and mutations.
    - Vectors: Genotypes represented as vectors and related configurations.
    - GeneticPrograms: Genotypes and phenotypes defined through genetic programs.

"""
module Substrates

export DefaultPhenotypeConfiguration, DefaultMutator
export BasicVectorGenotype, BasicVectorGenotypeConfiguration
export BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration
export PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration

# Core abstract types and interfaces
include("abstract/abstract.jl")

# Default configurations and utilities
include("types/defaults/defaults.jl")
using .Defaults: DefaultPhenotypeConfiguration, DefaultMutator

# Genotypes represented as vectors
include("types/vectors/vectors.jl")
using .Vectors: BasicVectorGenotype, BasicVectorGenotypeConfiguration

# Genotypes and phenotypes defined as genetic programs
include("types/genetic_programs/genetic_programs.jl")
using .GeneticPrograms: BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeConfiguration
using .GeneticPrograms: PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration

end
