abstract type Selector end

Base.@kwdef struct VRouletteSelector <: Selector
    rng::AbstractRNG
    n_elite::Int
end
function vroulette(rng::AbstractRNG, n_samples::Int, fitness::Vector{<:Real})
    probs = fitness / sum(fitness)
    sample(rng, 1:length(probs), Weights(probs), n_samples)
end

function(s::VRouletteSelector)(μ::Int, candidates::Dict{String, Individual})
    cands = collect(values(candidates))
    cfits = collect(zip(cands, [getfitness(c) for c in cands]))
    sort!(cfits, by = cf -> cf[2], rev = true, alg = Base.Sort.QuickSort)
    cands, fitnesses = collect(zip(cfits...))
    elites = [cands[i] for i in 1:s.n_elite]
    parent_idxs = vroulette(s.rng, μ, fitnesses)
    parents = [cands[i] for i in parent_idxs]
    Dict(e.key => e for e in elites), Dict(p.key => p for p in parents)
end

function(s::Selector)(μ::Int, comma::Bool, pop::VPop)
    candidates = comma ? pop.children : union(pop.children, pop.parents)
    s(μ, candidates)
end

function getfitness(indiv::Individual)
    sum([o.score for o in values(indiv.outcomes)])
end

function gettestscores(indiv::Individual)
    SortedDict([o.testkey => o.score for o in values(indiv.outcomes)])
end