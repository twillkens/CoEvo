module Replacers

export IdentityReplacer, TruncationReplacer, CommaReplacer
export GenerationalReplacer, DiscoReplacer

include("disco.jl")

using Random
using ...CoEvo: Individual, Species, Replacer

# Returns the poIndividuallation of veterans without change
struct IdentityReplacer <: Replacer end

function(r::IdentityReplacer)(::AbstractRNG, pop::Vector{<:Individual}, ::Vector{<:Individual})
    pop
end

# Returns the best npop individuals from both the population and children
Base.@kwdef struct TruncationReplacer <: Replacer
    npop::Int
end

function(r::TruncationReplacer)(
    ::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    sort([pop ; children], by = i -> fitness(i), rev = true)[1:r.npop]
end

# Replaces the population with the children, keeping the best n_elite individuals from the
# population
Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
    reverse::Bool = false
end

function(r::GenerationalReplacer)(
    ::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    if length(children) == 0
        return pop
    end
    elites = sort(pop, by = i -> fitness(i), rev = r.reverse)[1:r.n_elite]
    n_children = length(pop) - r.n_elite
    children = sort(children, by = i -> fitness(i), rev = r.reverse)[1:n_children]
    pop = [elites; children]
    pop

end

Base.@kwdef struct CommaReplacer <: Replacer
    npop::Int
end

function(r::CommaReplacer)(
    ::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    children = length(children) == 0 ? pop : children
    sort(children, by = i -> fitness(i), rev = true)[1:r.npop]
end


function(r::Replacer)(rng::AbstractRNG, species::Species)
    r(rng, collect(values(species.pop)), collect(values(species.children)))
end


Base.@kwdef struct DiscoReplacer <: Replacer
    npop::Int = 50
    xmeans_seed::UInt32 = UInt32(0)
end

function(r::DiscoReplacer)(
    rng::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    pop = [pop ; children] 
    seed = r.xmeans_seed == 0 ?  rand(rng, UInt32) : r.xmeans_seed
    set_derived_tests(pop, seed)
end

end