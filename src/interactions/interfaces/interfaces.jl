export interact

using ..Phenotypes: Phenotype

function interact(
    interaction::Interaction, individual_ids::Vector{Int}, phenotypes::Vector{Phenotype},
)
    throw(ErrorException(
        "`interact` not implemented for $(typeof(interaction)), $(typeof(phenotypes))"
    ))
end
