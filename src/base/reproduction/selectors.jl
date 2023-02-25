export IdentitySelector, RouletteSelector

# abstract type Selector end
struct IdentitySelector <: Selector
end

function(s::IdentitySelector)(::AbstractRNG, pop::Vector{<:Veteran})
    pop
end

Base.@kwdef struct RouletteSelector <: Selector
    μ::Int
end

function vroulette(rng::AbstractRNG, n_samples::Int, fitness::Vector{<:Real})
    probs = fitness / sum(fitness)
    sample(rng, 1:length(probs), Weights(probs), n_samples)
end

function pselection(rng::AbstractRNG, μ::Int, prob::Vector{<:Real})
    cp = cumsum(prob)
    selected = Array{Int}(undef, μ)
    for i in 1:μ
        j = 1
        r = rand(rng)
        while cp[j] < r
            j += 1
        end
        selected[i] = j
    end
    selected
end

function roulette(rng::AbstractRNG, μ::Int, fits::Vector{<:Real})
    absf = abs.(fits)
    prob = absf./sum(absf)
    pselection(rng, μ, prob)
end

function(s::RouletteSelector)(rng::AbstractRNG, pop::Vector{<:Veteran})
    fits = [fitness(vet) for vet in pop]
    pidxs = roulette(rng, s.μ, fits)
    pop[pidxs] 
end