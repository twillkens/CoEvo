export IdentitySelector, RouletteSelector, TournamentSelector

using StatsBase
using Random

# abstract type Selector end
struct IdentitySelector <: Selector
end

function(s::IdentitySelector)(::AbstractRNG, pop::Vector{<:Individual})
    pop
end

Base.@kwdef struct RouletteSelector <: Selector
    μ::Int
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

function(s::RouletteSelector)(rng::AbstractRNG, pop::Vector{<:Individual})
    fits = [fitness(vet) for vet in pop]
    println("--------------------")
    println(pop[1].geno)
    println(Expr(pop[1].geno))
    println(fits)
    pidxs = roulette(rng, s.μ, fits)
    pop[pidxs] 
end

Base.@kwdef struct TournamentSelector <: Selector
    μ::Int # number of parents to select
    tsize::Int # tournament size
    selection_func::Function = argmin # function to select the winner of the tournament
end

function(s::TournamentSelector)(rng::AbstractRNG, pop::Vector{<:Individual})
    fits = [fitness(vet) for vet in pop]
    println("--------------------")
    println(pop[1].geno)
    println(Expr(pop[1].geno))
    println(fits[1])
    pidxs = Array{Int}(undef, s.μ)
    for i in 1:s.μ
        tidxs = sample(rng, 1:length(pop), s.tsize, replace=false)
        pidxs[i] = tidxs[s.selection_func(fits[tidxs])]
    end
    pop[pidxs]
end