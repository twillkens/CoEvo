export IdentityReplacer, TruncationReplacer, GenerationalReplacer
export CommaReplacer
# export PlusReplacer

struct IdentityReplacer <: Replacer end

function(r::IdentityReplacer)(pop::Vector{<:Veteran}, ::Vector{<:Veteran})
    pop
end

struct TruncationReplacer <: Replacer end

function(r::TruncationReplacer)(pop::Vector{<:Veteran}, children::Vector{<:Veteran})
    npop = length(pop)
    sort([pop ; children], by = i -> fitness(i), rev = true)[1:npop]
end

Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
end

function(r::GenerationalReplacer)(pop::Vector{<:Veteran}, children::Vector{<:Veteran})
    if length(children) == 0
        return pop
    end
    npop = length(pop)
    elites = sort(pop, by = i -> fitness(i), rev = true)[1:r.n_elite]
    sort([elites; children], by = i -> fitness(i), rev = true)[1:npop]
end

# Base.@kwdef struct PlusReplacer <: Replacer end

# function(r::PlusReplacer)(species::Species)
#     n_pop = length(species.pop)
#     pop = collect(union(species.parents, species.children))
#     sort(pop, by = i -> getfitness(i), rev = true)[:n_pop]
# end

Base.@kwdef struct CommaReplacer <: Replacer
    n_pop::Int
end

function(r::CommaReplacer)(pop::Vector{<:Veteran}, children::Vector{<:Veteran})
    if length(children) == 0
        return pop
    end
    npop = length(pop)
    sort(children, by = i -> getfitness(i), rev = true)[1:npop]
end


function(r::Replacer)(species::Species)
    r(collect(values(species.pop)), collect(values(species.children)))
end