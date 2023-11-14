module Basic

export BasicSpecies

using ...Individuals: Individual
using ..Species: AbstractSpecies

"""
    BasicSpecies{P <: PhenotypeCreator, I <: Individual}

Represents a species population and its offspring.

# Fields
- `id::String`: Unique species identifier.
- `phenotype_creator::P`: Phenotype configuration.
- `population::OrderedDict{Int, I}`: Current population.
- `children::OrderedDict{Int, I}`: Offspring of the population.
"""
Base.@kwdef struct BasicSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    children::Vector{I}
end

end