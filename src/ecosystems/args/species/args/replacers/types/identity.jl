
# Returns the poIndividuallation of veterans without change
struct IdentityReplacer <: Replacer end

function(r::IdentityReplacer)(::AbstractRNG, pop::Vector{<:Evaluation}, ::Vector{<:Evaluation})
    pop
end
