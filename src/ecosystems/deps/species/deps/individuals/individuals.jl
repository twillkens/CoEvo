"""
    Individuals

A module dedicated to the definition and management of different types of individuals 
in a co-evolutionary system.
"""
module Individuals

export Individual

using ..Species.Genotypes.Abstract: Genotype

struct Individual{G <: Genotype}
    id::Int
    geno::G
    parent_ids::Vector{Int}
end

end
