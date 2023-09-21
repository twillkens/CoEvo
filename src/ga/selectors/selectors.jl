# This module contains 
module Selectors

export IdentitySelector, RouletteSelector, TournamentSelector, NSGASelector

using StatsBase
using Random
using ...CoEvo: Individual, Selector
using ..Evaluations: ScalarFitnessEval, DiscoEval

include("nsga.jl")

# abstract type Selector end
struct IdentitySelector <: Selector
end

function(s::IdentitySelector)(::AbstractRNG, pop::Vector{<:Individual})
    pop
end

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
    selected
end

function(s::RouletteSelector)(
    rng::AbstractRNG, pop::Vector{<:Individual}, evals::Dict{Int, ScalarFitnessEval}
)
    fitnesses = map(i -> evals[i].fitness, pop) 
    parent_idxs = roulette(rng, s.μ, fitnesses)
    pop[parent_idxs] 
end

Base.@kwdef struct TournamentSelector <: Selector
    μ::Int # number of parents to select
    tournament_size::Int # tournament size
    selection_func::Function = argmax # function to select the winner of the tournament
end

function(s::TournamentSelector)(
    rng::AbstractRNG, pop::Vector{<:Individual}, evals::Dict{Int, ScalarFitnessEval}
)
    fitnesses = map(i -> evals[i].fitness, pop) 
    parent_idxs = Array{Int}(undef, s.μ)
    for i in 1:s.μ
        tournament_idxs = sample(rng, 1:length(pop), s.tournament_size, replace=false)
        parent_idxs[i] = tidxs[s.selection_func(fitnesses[tournament_idxs])]
    end
    pop[parent_idxs]
end

Base.@kwdef struct NSGASelector <: Selector
    μ::Int = 50
    tsize::Int = 3
    sense::Sense = Max()
end

function(s::NSGASelector)(rng::AbstractRNG, pop::Vector{<:Individual}, evals::Dict{Int, DiscoEval})
    pop = nsga!(pop, )
    [nsga_tournament(rng, pop, c.tsize) for _ in 1:s.μ]
end

end