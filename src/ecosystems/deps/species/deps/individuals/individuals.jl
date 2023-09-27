"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system.
"""
module Individuals

export BasicIndividual, BasicIndividualCreator
export create_genotypes, create_phenotypes
export create_genotype, create_phenotype
export create_individuals, create_individual

include("abstract/abstract.jl")

using .Abstract

include("deps/models/models.jl")

include("types/basic.jl")

include("methods/methods.jl")


end
