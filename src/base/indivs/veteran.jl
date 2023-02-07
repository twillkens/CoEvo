export Veteran, VetSpecies
export dummyvets, clone
export iid, spkey

struct Veteran{I <: Individual, R <: Result} <: Individual
    indiv::I
    results::Set{R}
end

function dummyvets(indivs::Set{<:Individual})
    Set(Veteran(indiv, Set([ScalarResult(indiv.spkey, indiv.iid, "dummy", 1)]))
    for indiv in indivs)
end

function dummyvets(sp::Species)
    Species(sp.spkey, dummyvets(sp.pop), sp.parents, dummyvets(sp.children))
end

function clone(iid::Int, gen::Int, parent::Veteran)
    clone(iid, gen, parent.indiv)
end

function iid(vet::Veteran)
    vet.indiv.iid
end

function spkey(vet::Veteran)
    vet.indiv.spkey
end