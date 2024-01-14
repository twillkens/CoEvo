export replace

using ..Abstract

function replace(
    replacer::Replacer,
    rng::AbstractRNG, 
    species::AbstractSpecies,
    evaluation::Evaluation
)::Dict{Int, Individual}
    throw(ErrorException("replace not implemented for $replacer"))
end
