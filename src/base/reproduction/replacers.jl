export IdentityReplacer, TruncationReplacer, GenerationalReplacer
export CommaReplacer
# export PlusReplacer

struct IdentityReplacer <: Replacer end

function(r::IdentityReplacer)(pop::Vector{<:Veteran}, ::Vector{<:Veteran})
    pop
end

Base.@kwdef struct TruncationReplacer <: Replacer
    npop::Int
end

function(r::TruncationReplacer)(
    ::AbstractRNG, pop::Vector{<:Veteran}, children::Vector{<:Veteran}
)
    sort([pop ; children], by = i -> fitness(i), rev = true)[1:r.npop]
end

Base.@kwdef struct GenerationalReplacer <: Replacer
    npop::Int
    n_elite::Int = 0
end

function(r::GenerationalReplacer)(
    ::AbstractRNG, pop::Vector{<:Veteran}, children::Vector{<:Veteran}
)
    nkeep = length(pop) < r.n_elite ? length(pop) : r.n_elite
    elites = sort(pop, by = i -> fitness(i), rev = true)[1:nkeep]
    sort([elites; children], by = i -> fitness(i), rev = true)[1:r.npop]
end

Base.@kwdef struct CommaReplacer <: Replacer
    npop
end

function(r::CommaReplacer)(::AbstractRNG, pop::Vector{<:Veteran}, children::Vector{<:Veteran})
    sort(children, by = i -> fitness(i), rev = true)[1:r.npop]
end


function(r::Replacer)(rng::AbstractRNG, species::Species)
    r(rng, collect(values(species.pop)), collect(values(species.children)))
end