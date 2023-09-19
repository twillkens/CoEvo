# This module contains 
module Selectors

export IdentitySelector, RouletteSelector, TournamentSelector, NSGASelector

using StatsBase
using Random
using CSV, DataFrames

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

function append_stats_to_csv(pop)
    fits = [fitness(vet) for vet in pop]
    full_genos = [length(merge(i.geno.funcs, i.geno.terms)) for i in pop]
    pruned_genos = [pruned_size(geno.geno) for geno in pop]
    spid = pop[1].ikey.spid
    filename = "$spid.csv"
    
    # Calculate stats
    full_stats = (
        category="Full Geno Stats", 
        min=round(minimum(full_genos), digits=2), 
        max=round(maximum(full_genos), digits=2), 
        mean=round(mean(full_genos), digits=2), 
        median=round(median(full_genos), digits=2), 
        std=round(std(full_genos), digits=2)
    )
    pruned_stats = (
        category="Pruned Geno Stats",
        min=round(minimum(pruned_genos), digits=2), 
        max=round(maximum(pruned_genos), digits=2), 
        mean=round(mean(pruned_genos), digits=2), 
        median=round(median(pruned_genos), digits=2), 
        std=round(std(pruned_genos), digits=2)
    )
    fits_stats = (category="Fitness Stats", min=round(minimum(fits), digits=2), max=round(maximum(fits), digits=2), mean=round(mean(fits), digits=2), median=round(median(fits), digits=2), std=round(std(fits), digits=2))

    # Check if file exists
    if isfile(filename)
        df = CSV.File(filename) |> DataFrame
    else
        df = DataFrame(
            category=String[],
            min=Float64[],
            max=Float64[],
            mean=Float64[],
            median=Float64[],
            std=Float64[]
        )
    end

    # Append stats to dataframe
    push!(df, full_stats)
    push!(df, pruned_stats)
    push!(df, fits_stats)

    # Write to CSV
    CSV.write(filename, df, append=false)  # Overwrite the file with updated DataFrame
end

function(s::RouletteSelector)(rng::AbstractRNG, pop::Vector{<:Individual})
    spid = string(pop[1].ikey.spid)
    fits = [fitness(vet) for vet in pop]
    full_genos = [length(merge(i.geno.funcs, i.geno.terms)) for i in pop]
    pruned_genos = [pruned_size(geno.geno) for geno in pop]
    append_stats_to_csv(pop)
    println("---------$spid-----------")
    println("Full  -   Min: ", round(minimum(full_genos), digits=2), ", Max: ", round(maximum(full_genos), digits=2), ", Mean: ", round(mean(full_genos), digits=2), ", Median: ", round(median(full_genos), digits=2), ", Std: ", round(std(full_genos), digits=2))
    println("Prune -   Min: ", round(minimum(pruned_genos), digits=2), ", Max: ", round(maximum(pruned_genos), digits=2), ", Mean: ", round(mean(pruned_genos), digits=2), ", Median: ", round(median(pruned_genos), digits=2), ", Std: ", round(std(pruned_genos), digits=2))
    println("Fit   -   Min: ", round(minimum(fits), digits=2), ", Max: ", round(maximum(fits), digits=2), ", Mean: ", round(mean(fits), digits=2), ", Median: ", round(median(fits), digits=2), ", Std: ", round(std(fits), digits=2))
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
    # println("--------------------")
    # println(pop[1].geno)
    # println(Expr(pop[1].geno))
    # println(fits[1])
    pidxs = Array{Int}(undef, s.μ)
    for i in 1:s.μ
        tidxs = sample(rng, 1:length(pop), s.tsize, replace=false)
        pidxs[i] = tidxs[s.selection_func(fits[tidxs])]
    end
    pop[pidxs]
end

Base.@kwdef struct NSGASelector <: Selector
    μ::Int = 50
    tsize::Int = 3
    sense::Sense = Max()
end

function(s::NSGASelector)(rng::AbstractRNG, pop::Vector{<:Individual})
    pop = nsga!(pop, Max())
    [nsga_tournament(rng, pop, c.tsize) for _ in 1:s.μ]
end

end