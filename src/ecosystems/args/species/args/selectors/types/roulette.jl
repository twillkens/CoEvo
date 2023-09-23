Base.@kwdef struct RouletteSelector <: Selector
    μ::Int
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

function(selector::RouletteSelector)(
    rng::AbstractRNG, pop::Vector{<:Individual}, evals::Dict{Int, ScalarFitnessEval}
)
    fitnesses = map(i -> evals[i].fitness, pop) 
    parent_idxs = roulette(rng, selector.μ, fitnesses)
    parents = pop[parent_idxs] 
    return parents  
end
