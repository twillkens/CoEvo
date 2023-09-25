using Random
using ....CoEvo.Abstract: Replacer, Evaluation, Criterion
using ....CoEvo.Utilities.Criteria: Maximize

# Returns the best npop individuals from both the population and children
Base.@kwdef struct TruncationReplacer <: Replacer
    n_pop::Int = -1
    type::Symbol = :plus
    sort_criterion::Criterion = Maximize()
end


function(replacer::TruncationReplacer)(
    ::AbstractRNG, pop::Vector{<:Evaluation}, children::Vector{<:Evaluation}
)
    if length(children) == 0
        candidates = pop
    elseif replacer.type == :plus
        candidates = [pop ; children]
    elseif replacer.type == :comma
        candidates = children
    else
        throw(ErrorException("Invalid TruncationReplacer type: $(replacer.type)"))
    end
    if replacer.n_pop == -1
        return candidates
    end
    candidates = sort_evaluations(replacer.sort_criterion, candidates)
    new_pop_ids = [candidate.id for candidate in candidates[1:replacer.n_pop]]
    return new_pop_ids
end