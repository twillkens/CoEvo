export recombine

using ..Abstract

function recombine(
    recombiner::Recombiner,
    ::AbstractRNG, 
    ::Counter, 
    ::Vector{Individual}
)
    throw(ErrorException("recombine not implemented for $recombiner"))
end

function recombine(
    recombiner::Recombiner,
    ::Vector{Individual},
    state::State
)
    error("recombine not implemented for $recombiner")
end