export TruncationSelector

Base.@kwdef struct TruncationSelector <: Selector
    rng::AbstractRNG
    n_keep::Int
    n_elite::Int
    n_singles::Int
    n_couples::Int
end

# function TruncationSelector(key::String; rng=StableRNG(123),
#                           n_elite::Int = 0, n_singles = 25,
#                           n_couples = 0, n_keep = 10,
#                           kwargs...)
#     TruncationSelector(key, rng, n_keep, n_elite, n_singles, n_couples)
# end

function(r::TruncationSelector)(pop::Population, outcomes::Set{<:Outcome})
    rng, n_elite, n_singles, n_couples = r.rng, r.n_elite, r.n_singles, r.n_couples
    if n_elite + n_singles + n_couples != length(pop.genos)
        error("Invalid TruncationSelector configuration")
    end
    genos, _ = get_scores(pop, outcomes)
    elites = [genos[i] for i in 1:n_elite]
    genos = genos[1:r.n_keep]
    singles = [rand(rng, genos) for i in 1:n_singles]
    couples = [(rand(genos), rand(genos)) for i in 1:n_couples]
    GenoSelections(elites, singles, couples)
end
