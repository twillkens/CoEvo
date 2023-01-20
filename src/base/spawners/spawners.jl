export VSpawner

AllResultDict = Dict{String, Dict{String, EvalResult}}

@Base.kwdef mutable struct VSpawner{S <: VSelector, V <: Variator}
    key::String
    selector::S
    variators::Vector{V}
    currid::Int
end

struct VPop{G <: Genotype} <: Population
    key::String
    parents::Set{G}
    children::Set{G}
    resultdict::Dict{String, EvalResult}
    variationdict::Dict{String, VariationRecord}
end

function(s::VSpawner)(pops::Set{VPop}, coutcomes::Set{<:Outcome})
    pop = Dict{String, Population}(pops)[s.key]
    parents = s.selector(pop, coutcomes)
    children = deepcopy(parents)
    ids = [collect(range(s.currid, s.currid + length(children)))]
    s.currid += length(children) + 1 
    newvariations = Set()
    for v in s.variators
        children, variations = v(children, ids)
    end
    pkeys = Set([g.key for g in parents])
    poutcomes = filter(g -> g.key in pkeys, union(pop.poutcomes, coutcomes))
    VPop(pop.key, parents, children, poutcomes)
end

function(s::VSpawner)(pops::Set{VPop}, allresultdict::AllResultDict)
    pop = Dict{String, Population}(pops)[s.key]
    resultdict = allresultdict[s.key]
    parents = s.selector(pop, resultdict)
    children = deepcopy(parents)
    ids = [collect(range(s.currid, s.currid + length(children)))]
    s.currid += length(children) + 1 
    for v in s.variators
        children = v(children, ids)
    end
    pkeys = Set([g.key for g in parents])
    poutcomes = filter(g -> g.key in pkeys, union(pop.poutcomes, coutcomes))
    VPop(pop.key, parents, children, poutcomes)
end


Base.@kwdef struct NGBitstringMutator <: Variator
    rng::AbstractRNG
    mutrate::Float64
end

function(m::BitstringMutator)(key::String, parent::BitstringGeno)
    new_genes = [rand(m.rng) < m.mutrate ?
        rand(m.rng, Bool) : bit for bit in parent.genes]
    BitstringGeno(key, new_genes, Set([parent.key]))
end


function make_records(genos::Set{<:Genotype}, outcomes::Set{ScalarOutcome}) 
    odict = Dict{String, SortedDict{String, Float64}}()
    for o in outcomes
        for r in o.results
            if r.key ∉ keys(odict)
                odict[r.key] = SortedDict(r.testkey => r.score)
            else
                odict[r.key][r.testkey] = r.score
            end

        end
    end
    gdict = Dict{String, Genotype}(genos)
    [NSGAiiRecord(geno, odict[key]) for geno in values(gdict)]
end


struct EvalResult{G <: Genotype, O <: Outcome, R <: Result}
    geno::G
    outcomes::Vector{O}
    fitness::Float64
    tests::SortedDict{String, Float64}
end

function gkey(result::EvalResult)
    result.geno.key
end

function pkey(geno::Genotype)
    split(geno.key, KEY_SPLIT_TOKEN)[1]
end

function pkey(result::EvalResult)
    pkey(result.geno)
end

function EvalResult(geno::Genotype, outcomes::Vector{<:Outcome})
    tests = SortedDict([o.testkey => o.score for o in outcomes])
    fitness = sum(values(tests))
    EvalResult(geno, outcomes, fitness, tests)
end

function Set{EvalResult}(genos::Set{<:Genotype}, outcomes::Set{<:Outcome}) 
    gdict = Dict([g.key => g for g in genos])
    odict = SortedDict([o.genokey => Outcome[] for o in outcomes])
    [push!(odict[o.genokey], o) for o in outcomes]
    Set([EvalResult(genome, odict[key]) for (key, genome) in gdict])
end


function Dict{String, EvalResult}(pops::Set{<:Population}, child_outcomes::Set{<:Outcome})
    outcomes = Set{Outcome}()
    union!(outcomes, child_outcomes)
    genos = Set{Genotype}()
    for pop in pops
        [union!(genos, pop.parents)]
        [union!(genos, pop.children)]
        [union!(outcomes, pop.poutcomes)]
    end
    results = Set{EvalResult}(genos, outcomes)
    rpairs = [r.key => r for r in results]
    Dict([pop.key => Dict(filter(r -> pkey(r[2]) == pop.key, rpairs)) for pop in pops])
end

function(c::CoevConfig)(gen::Int, pops::Set{VPop})
    jobs = c.job_cfg(c.orders, pops)
    child_outcomes = Set{Outcome}(jobs)
    resultdict = Dict{String, EvalResult}(pops, child_outcomes)
    gen_group = JLD2.Group(c.jld2file, string(gen))
    gen_group["rng"] = copy(c.rng)
    [logger(gen_group, pops, resultdict) for logger in c.loggers]
    Set([spawner(pops, resultdict) for spawner in c.spawners])
end

struct ScoreOutcome <: Outcome
    mixn::Int
    genokey::String
    testkey::String
    role::Symbol
    score::Float64
end

Base.@kwdef struct VRouletteSelector <: Selector
    rng::AbstractRNG
    n_elite::Int
    n_singles::Int
    n_couples::Int
end
function roulette_old(rng::AbstractRNG, n_samples::Int, fitness::Vector{<:Real})
    probs = fitness / sum(fitness)
    probs, sample(rng, 1:length(probs), Weights(probs), n_samples)
end

function(s::VRouletteSelector)(pop::Population, outcomes::Set{<:Outcome})
    genos, fitness = get_scores(pop, outcomes)
    elites = [genos[i] for i in 1:s.n_elite]
    probs, singles_idxs = roulette_old(s.rng, s.n_singles, fitness)
    singles = [genos[i] for i in singles_idxs]
    probs, couples_idxs = roulette_old(s.rng, s.n_couples * 2, fitness)
    couples = [(genos[idxs[i]], genos[idxs[i + 1]]) for i in 1:2:length(couples_idxs)]
    probs = map(x -> round(x, digits=3), probs)
    GenoSelections(elites, singles, couples)
end