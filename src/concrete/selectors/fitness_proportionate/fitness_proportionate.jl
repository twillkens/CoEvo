module FitnessProportionate

export FitnessProportionateSelector, roulette

import ....Interfaces: select

using DataStructures: OrderedDict
using ....Abstract
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluation

Base.@kwdef struct FitnessProportionateSelector <: Selector
    n_parents::Int
end

function roulette(
    rng::AbstractRNG, n_parents::Int, fitnesses::Vector{<:Real}
)
    if any(fitnesses .<= 0)
        throw(ArgumentError("Fitness values must be strictly positive for FitnessProportionateSelector."))
    end
    probabilities = fitnesses ./ sum(fitnesses)
    cumulative_probabilities = cumsum(probabilities)
    parents = Array{Int}(undef, n_parents)
    spins = rand(rng, n_parents)
    for (n_parent, spin) in enumerate(spins)
        candidate_index = 1
        while cumulative_probabilities[candidate_index] < spin
            candidate_index += 1
        end
        parents[n_parent] = candidate_index
    end
    return parents
end

function select(
    selector::FitnessProportionateSelector,
    rng::AbstractRNG, 
    new_population::Vector{<:Individual},
    evaluation::Evaluation
)
    ids = [individual.id for individual in new_population]
    records_dict = Dict(record.id => record for record in evaluation.records)
    fitnesses = [records_dict[id].fitness for id in ids]
    parent_indices = roulette(rng, selector.n_parents, fitnesses)
    parents = [new_population[i] for i in parent_indices]
    return parents  
end

select(
    selector::FitnessProportionateSelector,
    new_population::Vector{<:Individual},
    evaluation::Evaluation,
    state::State
) = select(selector, state.rng, new_population, evaluation)

end