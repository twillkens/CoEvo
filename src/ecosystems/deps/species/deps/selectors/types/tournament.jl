module Tournament

using ...Selectors.Abstract: Selector
using StatsBase: sample
using Random: AbstractRNG
using ....Evaluators.Abstract: Evaluation
using ....Evaluators.Types.ScalarFitness: ScalarFitnessRecord
using ....Evaluators.Types.NSGAII: NSGAIIRecord
using ....Species.Individuals: Individual

import ...Selectors.Interfaces: select


Base.@kwdef struct TournamentSelector <: Selector
    n_parents::Int # number of parents to select
    tournament_size::Int # tournament size
end


function run_tournament(rng::AbstractRNG, contenders::Array{<:ScalarFitnessRecord}) 
    function get_winner(d1::ScalarFitnessRecord, d2::ScalarFitnessRecord)
        if d1.fitness > d2.fitness
            return d1
        elseif d2.fitness > d1.fitness
            return d2
        else
            return rand(rng, (d1, d2))
        end
    end
    winner = reduce(get_winner, contenders)
    return winner
end

function run_tournament(rng::AbstractRNG, contenders::Array{<:NSGAIIRecord}) 
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
    winner = reduce(get_winner, contenders)
    return winner
end

function select(
    selector::TournamentSelector,
    rng::AbstractRNG, 
    new_population::Vector{I},
    evaluation::Evaluation
) where {I <: Individual}
    # Fetch NSGAIIRecord for each individual
    new_population_dict = Dict(individual.id => individual for individual in new_population)
    records = filter(record -> record.id in keys(new_population_dict), evaluation.records)
    #println("ids: ", [record.id for record in records])
    
    parents = I[]
    for _ in 1:selector.n_parents
        # Get tournament contenders
        # TODO: make false once rng bug fixed.
        #contenders = sample(rng, records, selector.tournament_size, replace=false)
        contenders = sample(rng, records, selector.tournament_size, replace=true)
        
        # Select a winner from the contenders
        winner = run_tournament(rng, contenders)
        
        # Extract the individual associated with the winning record
        push!(parents, new_population_dict[winner.id])
    end
    
    return parents
end


end