export interact

using ..Abstract

function interact(
    interaction::Interaction, individual_ids::Vector{Int}, phenotypes::Vector{Phenotype},
)
    interaction = typeof(interaction)
    individual_ids = typeof(individual_ids)
    phenotypes = typeof(phenotypes)
    error("interact not implemented for $interaction, $individual_ids, $phenotypes")
end