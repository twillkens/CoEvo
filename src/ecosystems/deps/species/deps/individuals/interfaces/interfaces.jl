module Interfaces

export create_individual

using ..Individuals.Abstract: Individual, IndividualCreator
using ...Species.Genotypes.Abstract: Genotype

function create_individual(
    indiv_creator::IndividualCreator, 
    indiv_id::Int, 
    geno::Genotype, 
    parent_ids::Vector{Int}
)::Individual
    throw(ErrorException(
        "Default individual creation for $indiv_creator, $geno, not implemented."
    ))
end

end