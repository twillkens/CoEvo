module Abstract

export Recombiner, recombine

abstract type Recombiner end

function recombine(
    recombiner::Recombiner,
    ::AbstractRNG, 
    ::Counter, 
    ::Vector{Individual}
)
    throw(ErrorException("recombine not implemented for $recombiner"))
end

end