export Spawner, Gene, Species
export ScoreOutcome, IdentitySelector, Replacer

@Base.kwdef struct Spawner{I <: IndivConfig, R <: Replacer, S <: Selector, V <: Variator}
    spkey::String
    n_pop::Int
    icfg::I
    replacer::R
    selector::S
    variator::V
end

function(s::Spawner)(gen::Int, sp::Species,)
    pop = s.replacer(sp)
    parents = s.selector(pop)
    children = s.variator(s.spkey, gen, parents)
    Species(s.spkey, pop, parents, children)
end

function(s::Spawner)(args...)
    iids = iids!(s.variator, s.n_pop)
    pop = s.icfg(s.variator, iids, args...)
    itype = typeof(pop).parameters[1]
    Species(s.spkey, pop, Vector{itype}(), Set{itype}())
end