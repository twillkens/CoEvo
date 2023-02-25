export Spawner, Species
export ScoreOutcome, IdentitySelector, Replacer
export EvoState

@Base.kwdef struct Spawner{
    I <: IndivConfig, P <: PhenoConfig, RP <: Replacer, S <: Selector,
    RC <: Recombiner, M <: Mutator
}
    spid::Symbol
    npop::Int
    icfg::I
    phenocfg::P
    replacer::RP
    selector::S
    recombiner::RC
    mutators::Vector{M}
    spargs::Vector{Any} = Any[]
end

function(s::Spawner)(rng::AbstractRNG, sc::SpawnCounter, vets::Species)
    pop = s.replacer(rng, vets)
    parents = s.selector(rng, pop)
    children = s.recombiner(rng, sc, parents)
    for mutator in s.mutators
        children = mutator(rng, sc, children)
    end
    Species(s.spid, s.phenocfg, [vet.indiv for vet in pop], children)
end

function(s::Spawner)(rng::AbstractRNG, sc::SpawnCounter)
    pop = s.icfg(rng, sc, s.npop, s.spargs...)
    Species(s.spid, s.phenocfg, pop)
end

function(s::Spawner)(evostate::EvoState)
    s(evostate.rng, evostate.counters[s.spid])
end

function(s::Spawner)(evostate::EvoState, allvets::Dict{Symbol, <:Species})
    s(evostate.rng, evostate.counters[s.spid], allvets[s.spid])
end

function Species(rng::AbstractRNG, sc::SpawnCounter, s::Spawner, args...)
    pop = s.icfg(rng, sc, s.npop, args...)
    Species(s.spid, s.phenocfg, pop)
end

function Species(evostate::EvoState, s::Spawner, args...)
    Species(evostate.rng, evostate.counters[s.spid], s, args...)
end

function EvoState(rng::AbstractRNG, spawners::Dict{Symbol, <:Spawner})
    EvoState(rng, map(s -> s.spid, values(spawners)))
end

function EvoState(seed::Union{UInt64, Int}, spawners::Dict{Symbol, <:Spawner})
    EvoState(StableRNG(seed), spawners)
end