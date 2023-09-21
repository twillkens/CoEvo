module Individuals

using ...CoEvo: Genotype, Individual

"""
    Indiv{G <: Genotype} <: Individual

Represents an individual with a genotype, an identifier, and a parent identifier.

# Fields
- `id::Int`: The unique identifier for the individual.
- `geno::G`: The genotype of the individual.
- `pid::Int`: Identifier of the parent. It's `0` if the individual does not have a known parent.
"""
struct Indiv{G <: Genotype} <: Individual
    id::Int
    geno::G
    pid::Int
end

"""
    Indiv(id::Int, geno::Genotype)

Create an `Indiv` object with the given id and genotype. 
The parent id is set to `0` by default.
"""
Indiv(id::Int, geno::Genotype) = Indiv(id, geno, 0)

end