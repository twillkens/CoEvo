export replace

function replace(
    replacer::Replacer,
    random_number_generator::AbstractRNG, 
    species::AbstractSpecies,
    evaluation::Evaluation
)::Dict{Int, Individual}
    throw(ErrorException("replace not implemented for $replacer"))
end
