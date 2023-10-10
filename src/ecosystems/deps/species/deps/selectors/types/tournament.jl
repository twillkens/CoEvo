module Tournament

using ...Selectors.Abstract: Selector
using StatsBase: sample
using Random: AbstractRNG
using ....Evaluators.Interfaces: get_ranked_ids
using ....Evaluators.Types.ScalarFitness: ScalarFitnessEvaluation
using ....Evaluators.Types.NSGAII: NSGAIIEvaluation, NSGAIIRecord
using ....Species.Individuals: Individual

import ...Selectors.Interfaces: select


Base.@kwdef struct TournamentSelector <: Selector
    μ::Int # number of parents to select
    tournament_size::Int # tournament size
    selection_func::Function = argmax # function to select the winner of the tournament
end

function nsga_tournament(rng::AbstractRNG, parents::Array{<:NSGAIIRecord}, tourn_size::Int64) 
    function get_winner(d1::NSGAIIRecord, d2::NSGAIIRecord)
        if d1.rank < d2.rank
            return d1
        elseif d2.rank < d1.rank
            return d2
        else
            if d1.crowding > d2.crowding
                return d1
            elseif d2.crowding > d1.crowding
                return d2
            else
                return rand(rng, (d1, d2))
            end
        end
    end
    contenders = rand(rng, parents, tourn_size)
    reduce(get_winner, contenders)
end

function select(
    selector::TournamentSelector,
    rng::AbstractRNG, 
    new_pop::Dict{Int, I},
    evaluation::NSGAIIEvaluation
) where {I <: Individual}
    # Fetch NSGAIIRecord for each individual
    records = evaluation.disco_records
    records = filter(record -> record.id in keys(new_pop), records)
    
    parents = I[]
    for i in 1:selector.μ
        # Get tournament contenders
        contenders = sample(rng, records, selector.tournament_size, replace=false)
        
        # Select a winner from the contenders
        winner = nsga_tournament(rng, contenders, selector.tournament_size)
        
        # Extract the individual associated with the winning record
        push!(parents, new_pop[winner.id])
    end
    
    return parents
end


#function select(
#    selector::TournamentSelector,
#    rng::AbstractRNG, 
#    new_pop::Dict{Int, <:Individual},
#    evaluation::NSGAIIEvaluation
#)
#    ranked_ids = get_ranked_ids(evaluation, collect(keys(new_pop)))
#    parent_idxs = Array{Int}(undef, selector.μ)
#    for i in 1:selector.μ
#        tournament_idxs = sample(rng, 1:length(ranked_ids), selector.tournament_size, replace=false)
#        parent_idx = selector.selection_func(tournament_idxs)
#        parent_idxs[i] = ranked_ids[parent_idx]
#    end
#    parents = [new_pop[idx] for idx in parent_idxs]
#    return parents
#end

end