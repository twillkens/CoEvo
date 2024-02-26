export recombine

using ..Abstract

function recombine(recombiner::Recombiner, individuals::Vector{Individual}, state::State)
    recombiner = typeof(recombiner)
    individuals = typeof(individuals)
    state = typeof(state)
    error("recombine not implemented for $recombiner, $individuals, $state")
end

function recombine(recombiner::Recombiner, mutator::Mutator, individuals::Vector{Individual}, state::State)
    recombiner = typeof(recombiner)
    mutator = typeof(mutator)
    individuals = typeof(individuals)
    state = typeof(state)
    error("recombine not implemented for $recombiner, $mutator, $individuals, $state")
end