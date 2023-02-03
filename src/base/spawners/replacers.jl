export IdentityReplacer, TruncationReplacer, GenerationalReplacer
export PlusReplacer, CommaReplacer

struct IdentityReplacer <: Replacer end

function(r::IdentityReplacer)(species::Species)
    collect(values(species.pop))
end

struct TruncationReplacer <: Replacer end

function(r::TruncationReplacer)(species::Species)
    n_pop = length(species.pop)
    pop = collect(union(species.pop, species.children))
    Set(sort(pop, by = i -> getfitness(i), rev = true)[:n_pop])
end

Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
end

function(r::GenerationalReplacer)(species::Species)
    n_pop = length(species.pop)
    elites = sort(collect(species.pop),
        by = i -> getfitness(i), rev = true)[:r.n_elite]
    Set(sort([elites; collect(species.children)],
        by = i -> getfitness(i), rev = true)[:n_pop])
end

Base.@kwdef struct PlusReplacer <: Replacer end

function(r::PlusReplacer)(species::Species)
    n_pop = length(species.pop)
    pop = collect(values(merge(species.parents, species.children)))
    sort(pop, by = i -> getfitness(i), rev = true)[:n_pop]
end

Base.@kwdef struct CommaReplacer <: Replacer
    n_pop::Int
end

function(r::CommaReplacer)(species::Species)
    n_pop = length(species.pop)
    pop = collect(values(species.children))
    pop = sort(pop, by = i -> getfitness(i), rev = true)[:n_pop]
end