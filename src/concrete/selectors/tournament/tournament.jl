module Tournament

export TournamentSelector, run_tournament

import ....Interfaces: select
using ....Abstract
using ...Evaluators.ScalarFitness: ScalarFitnessRecord
using ...Evaluators.NSGAII: NSGAIIRecord
using ...Evaluators.Disco: DiscoRecord
using ...Selectors.Selections: BasicSelection
using StatsBase: sample
using Random

Base.@kwdef struct TournamentSelector <: Selector
    n_selections::Int # number of selections to make
    n_selection_set::Int # number of individuals to select in each selection
    tournament_size::Int # tournament size
end

function run_tournament(contenders::Array{<:ScalarFitnessRecord}, rng::AbstractRNG) 
    function get_winner(record_1::ScalarFitnessRecord, record_2::ScalarFitnessRecord)
        if record_1.scaled_fitness > record_2.scaled_fitness
            return record_1
        elseif record_2.scaled_fitness > record_1.scaled_fitness
            return record_2
        else
            return rand(rng, (record_1, record_2))
        end
    end
    winner = reduce(get_winner, contenders)
    return winner
end

function run_tournament(contenders::Array{<:DiscoRecord}, rng::AbstractRNG) 
    function get_winner(record_1::DiscoRecord, record_2::DiscoRecord)
        if record_1.rank < record_2.rank
            return record_1
        elseif record_2.rank < record_1.rank
            return record_2
        else
            if record_1.crowding > record_2.crowding
                return record_1
            elseif record_2.crowding > record_1.crowding
                return record_2
            else
                return rand(rng, (record_1, record_2))
            end
        end
    end
    winner = reduce(get_winner, contenders)
    return winner
end

function select(
    ::TournamentSelector,
    records::Vector{<:Record},
    tournament_size::Int,
    rng::AbstractRNG,
)
    contenders = sample(rng, records, tournament_size, replace = false)
    winner = run_tournament(contenders, rng)
    return winner
end

function select(
    selector::TournamentSelector,
    records::Vector{R},
    n_selection_set::Int,
    tournament_size::Int,
    rng::AbstractRNG 
) where {R <: Record}
    selection_set = R[]
    for _ in 1:n_selection_set
        winner = select(selector, records, tournament_size, rng)
        push!(selection_set, winner)
    end
    selection = BasicSelection(selection_set)
    return selection
end

function select(
    selector::TournamentSelector,
    records::Vector{<:Record},
    n_selections::Int,
    n_selection_set::Int,
    tournament_size::Int,
    rng::AbstractRNG,
)
    selections = BasicSelection[]
    for _ in 1:n_selections
        selection = select(selector, records, n_selection_set, tournament_size, rng)
        push!(selections, selection)
    end
    return selections
end

function select(
    selector::TournamentSelector,
    records::Vector{<:Record},
    state::State
)
    selections = select(
        selector, 
        records,
        selector.n_selections, 
        selector.n_selection_set, 
        selector.tournament_size,
        state.rng
    )
    return selections
end


end