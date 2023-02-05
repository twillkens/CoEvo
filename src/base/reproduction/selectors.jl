export IdentitySelector, VRouletteSelector

# abstract type Selector end
struct IdentitySelector <: Selector
end

function(s::IdentitySelector)(pop::Set{<:Individual})
    collect(pop)
end

Base.@kwdef struct VRouletteSelector <: Selector
    μ::Int
    rng::AbstractRNG
end

function vroulette(rng::AbstractRNG, n_samples::Int, fitness::Vector{<:Real})
    probs = fitness / sum(fitness)
    sample(rng, 1:length(probs), Weights(probs), n_samples)
end

function(s::VRouletteSelector)(pop::Set{<:Individual})
    indivfits = collect(zip(pop, [getfitness(indiv) for indiv in pop]))
    sort!(indivfits, by = cf -> cf[2], rev = true, alg = Base.Sort.QuickSort)
    cands, fitnesses = collect(zip(cfits...))
    parent_idxs = vroulette(s.rng, μ, fitnesses)
    [cands[i] for i in parent_idxs]
end