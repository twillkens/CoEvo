export VSpawner, Gene, Species
export ScoreOutcome, IdentitySelector, Replacer

@Base.kwdef struct VSpawner{I <: IndivConfig, R <: Replacer, S <: Selector, V <: Variator}
    spkey::String
    n_pop::Int
    icfg::I = VectorIndivConfig(Bool, 10)
    replacer::R = IdentityReplacer()
    selector::S = IdentitySelector()
    variator::V = IdentityVariator()
end

function(s::VSpawner)(gen::Int, sp::Species,)
    pop = s.replacer(sp)
    parents = s.selector(pop)
    children = s.variator(s.spkey, gen, parents)
    Species(s.spkey, pop, parents, children)
end

function(s::VSpawner)(args...)
    iids = iids!(s.variator, s.n_pop)
    pop = s.icfg(s.variator, iids, args...)
    itype = typeof(pop).parameters[1]
    Species(s.spkey, pop, Vector{itype}(), Set{itype}())
end