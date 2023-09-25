
export FitnessProportionateSelector

using Random: AbstractRNG
using DataStructures: OrderedDict
using ....CoEvo.Abstract: Individual, Evaluation, Selector

Base.@kwdef struct FitnessProportionateSelector <: Selector
    n_parents::Int
end

function roulette(rng::AbstractRNG, μ::Int, fits::Vector{<:Real})
    absolute_fitness = abs.(fits)
    probs = absolute_fitness./sum(absolute_fitness)
    cumulative_probs = cumsum(probs)
    selected = Array{Int}(undef, μ)
    for i in 1:μ
        j = 1
        r = rand(rng)
        while cumulative_probs[j] < r
            j += 1
        end
        selected[i] = j
    end
    return selected
end

function(selector::FitnessProportionateSelector)(
    rng::AbstractRNG, 
    new_pop_evals::OrderedDict{<:Individual, <:Evaluation}
)
    fitnesses = [eval.fitness for eval in values(new_pop_evals)]
    parent_indices = roulette(rng, selector.n_parents, fitnesses)
    parents = collect(keys(new_pop_evals))[parent_indices]
    return parents  
end
