module Basic

export BasicMatch

using ....Abstract

struct BasicMatch <: Match
    interaction_id::String
    individual_ids::Tuple{Int, Int}
    species_ids::Tuple{String, String}
end

end