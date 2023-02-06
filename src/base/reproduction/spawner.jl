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
end

function(s::Spawner)(gen::Int, sp::VetSpecies)
    pop = s.replacer(sp)
    parents = s.selector(pop)
    children = s.recombiner(gen, parents)
    for mutator in s.mutators
        children = mutator(gen, children)
    end
    children
    Species(
        s.spkey,
        Set(vet.indiv for vet in pop),
        [iid(p) for p in parents],
        children)
end

function(s::Spawner)(args...)
    pop = s.icfg(s.n_pop, args...)
    Species(s.spkey, pop,)
end