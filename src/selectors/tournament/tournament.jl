module Tournament

export TournamentSelector, run_tournament

import ...Selectors: select

using StatsBase: sample
using Random: AbstractRNG
using ...Individuals: Individual
using ...Evaluators: Evaluation
using ...Evaluators.ScalarFitness: ScalarFitnessRecord
using ...Evaluators.NSGAII: NSGAIIRecord
using ..Selectors: Selector

Base.@kwdef struct TournamentSelector <: Selector
    n_parents::Int # number of parents to select
    tournament_size::Int # tournament size
end

function run_tournament(
    random_number_generator::AbstractRNG, contenders::Array{<:ScalarFitnessRecord}
) 
    function get_winner(record_1::ScalarFitnessRecord, record_2::ScalarFitnessRecord)
        if record_1.fitness > record_2.fitness
            return record_1
        elseif record_2.fitness > record_1.fitness
            return record_2
        else
            return rand(random_number_generator, (record_1, record_2))
        end
    end
    winner = reduce(get_winner, contenders)
    return winner
end

function run_tournament(random_number_generator::AbstractRNG, contenders::Array{<:NSGAIIRecord}) 
    function get_winner(record_1::NSGAIIRecord, record_2::NSGAIIRecord)
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
                return rand(random_number_generator, (record_1, record_2))
                if record_1.fitness > record_2.fitness
                    return record_1
                elseif record_2.fitness > record_1.fitness
                    return record_2
                else
                    return rand(random_number_generator, (record_1, record_2))
                end
            end
        end
    end
    winner = reduce(get_winner, contenders)
    return winner
end

function select(
    selector::TournamentSelector,
    random_number_generator::AbstractRNG, 
    new_population::Vector{I},
    evaluation::Evaluation
) where {I <: Individual}
    new_population_dict = Dict(individual.id => individual for individual in new_population)
    records = filter(record -> record.id in keys(new_population_dict), evaluation.records)
    parents = I[]
    for _ in 1:selector.n_parents
        # Get tournament contenders
        contenders = sample(
            random_number_generator, records, selector.tournament_size, replace = false
        )
        # Select a winner from the contenders
        winner = run_tournament(random_number_generator, contenders)
        # Extract the individual associated with the winning record
        push!(parents, new_population_dict[winner.id])
    end
    
    return parents
end

end