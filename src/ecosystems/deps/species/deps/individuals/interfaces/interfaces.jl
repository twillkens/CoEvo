module Interfaces

export create_individual

using ..Abstract: Individual, IndividualCreator
using ..Individuals.Genotypes.Abstract: Genotype

function create_individual(
    indiv_creator::IndividualCreator, 
    ::Int, 
    geno::Genotype, 
    parent_ids::Vector{Int}
)::Individual
    throw(ErrorException(
        "Default individual creation for $indiv_creator, $geno, not implemented."
    ))
end

end