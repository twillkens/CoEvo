module Interfaces

export interact

using ..Interactions.Abstract: Interaction
using ...Species.Phenotypes.Abstract: Phenotype

function interact(
    interaction::Interaction,
    indiv_ids::Vector{Int},
    phenotypes::Vector{Phenotype},
)
    throw(ErrorException(
        "`interact` not implemented for $(typeof(interaction)), $(typeof(phenotypes))"
    ))
end

end