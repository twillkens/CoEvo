export RouletteSelector
export RouletteOldSelector

Base.@kwdef struct RouletteSelector <: Selector
    rng::AbstractRNG
    n_elite::Int
    n_singles::Int
    n_couples::Int
end

function pselection(rng::AbstractRNG, prob::Vector{<:Real}, N::Int)
    cp = cumsum(prob)
    selected = Array{Int}(undef, N)
    for i in 1:N
        j = 1
        r = rand(rng)
        while cp[j] < r
            j += 1
        end
        selected[i] = j
    end
    return selected
end

function roulette(fitness::Vector{<:Real}, N::Int;
                  rng::AbstractRNG)
    absf = abs.(fitness)
    prob = absf./sum(absf)
    return pselection(rng, prob, N)
end

function(r::RouletteSelector)(pop::Population, outcomes::Set{<:Outcome})
    rng, n_elite, n_singles, n_couples = r.rng, r.n_elite, r.n_singles, r.n_couples
    if n_elite + n_singles + n_couples != length(pop.genos)
        error("Invalid RouletteSelector configuration")
    end
    genos, fitness = get_scores(pop, outcomes)
    elites = [genos[i] for i in 1:n_elite]
    singles = [genos[i] for i in roulette(fitness, n_singles; rng = rng)]
    idxs = roulette(fitness, n_couples * 2; rng = rng)
    couples = [(genos[idxs[i]], genos[idxs[i + 1]]) for i in 1:2:length(idxs)]
    GenoSelections(elites, singles, couples)
end

Base.@kwdef struct RouletteOldSelector <: Selector
    rng::AbstractRNG
    n_elite::Int
    n_singles::Int
    n_couples::Int
end
function roulette_old(rng::AbstractRNG, n_samples::Int, fitness::Vector{<:Real})
    probs = fitness / sum(fitness)
    probs, sample(rng, 1:length(probs), Weights(probs), n_samples)
end

function(s::RouletteOldSelector)(pop::Population, outcomes::Set{<:Outcome})
    if s.n_elite + s.n_singles + s.n_couples != length(pop.genos)
        error("Invalid RouletteOldSelector configuration: $(length(pop.genos)), $(s.n_elite), $(s.n_singles), $(s.n_couples)")
    end
    genos, fitness = get_scores(pop, outcomes)
    elites = [genos[i] for i in 1:s.n_elite]
    probs, singles_idxs = roulette_old(s.rng, s.n_singles, fitness)
    singles = [genos[i] for i in singles_idxs]
    probs, couples_idxs = roulette_old(s.rng, s.n_couples * 2, fitness)
    couples = [(genos[idxs[i]], genos[idxs[i + 1]]) for i in 1:2:length(couples_idxs)]
    probs = map(x -> round(x, digits=3), probs)
    GenoSelections(elites, singles, couples)
end
