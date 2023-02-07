export Spawner, Gene, Species
export ScoreOutcome, IdentitySelector, Replacer

@Base.kwdef struct Spawner{
    I <: IndivConfig, RP <: Replacer, S <: Selector,
    RC <: Recombiner, M <: Mutator
}
    spkey::String
    n_pop::Int
    icfg::I
    replacer::RP
    selector::S
    recombiner::RC
    mutators::Vector{M}
    args::Vector{Any} = Any[]
end

function(s::Spawner)(gen::UInt16, sp::Species{<:Veteran})
    pop = s.replacer(sp)
    parents = s.selector(pop)
    children = s.recombiner(gen, parents)
    for mutator in s.mutators
        children = mutator(children)
    end
    Species(
        s.spkey,
        Set(vet.indiv for vet in pop),
        [iid(p) for p in parents],
        children)
end

function(s::Spawner)(gen::UInt16, allsp::Set{<:Species{<:Veteran}})
    spd = Dict(sp.spkey => sp for sp in allsp)
    s(gen, spd[s.spkey])
end


function(s::Spawner)(args...)
    pop = s.icfg(s.n_pop, args...)
    Species(s.spkey, pop,)
end

function(s::Spawner)()
    pop = length(s.args) > 0 ? s.icfg(s.n_pop, s.args...) : s.icfg(s.n_pop)
    Species(s.spkey, pop,)
end