export Spawner, Species
export ScoreOutcome, IdentitySelector, Replacer

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

function(s::Spawner)(vets::Species{<:Veteran})
    pop = s.replacer(vets)
    parents = s.selector(pop)
    children = s.recombiner(parents)
    for mutator in s.mutators
        children = mutator(children)
    end
    Species(s.spid, s.phenocfg, [vet.indiv for vet in pop], children)
end


function(s::Spawner)(allvets::Set{<:Species{<:Veteran}})
    s(first(filter(vets -> vets.spid == s.spid, allvets)))
end


function Species(s::Spawner, args...)
    pop = s.icfg(s.npop, args...)
    Species(s.spid, s.phenocfg, pop)
end

function(s::Spawner)()
    pop = s.icfg(s.npop, s.spargs...)
    Species(s.spid, s.phenocfg, pop)
end
