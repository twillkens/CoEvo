
Base.@kwdef struct LingPredMutator <: Mutator
    rng::AbstractRNG
    sc::SpawnCounter
    nmut::Int
end


function(m::LingPredMutator)(indivs::Set{<:FSMIndiv})

end