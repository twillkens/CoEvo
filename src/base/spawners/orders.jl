
Base.@kwdef struct VAllvsAllOrder{D <: Domain, P <: PhenoConfig} <: Order
    domain::D
    outcome::Type{<:Outcome}
    poproles::Dict{String, PopRole{P}}
end

function getroles(o::Order, pop::VPop) 
    if pop.key ∉ keys(o.poproles)
        throw(Error("Popkey not in poproles"))
    end
    poprole = o.poproles[pop.key]
    return [EntityRole(indiv.geno, poprole) for indiv in pop.indivs]
end

function(o::VAllvsAllOrder)(pop1::VPop, pop2::VPop)
    roles1 = getroles(o, pop1)
    roles2 = getroles(o, pop2)
    pairs = unique(Set, Iterators.filter(allunique,
                   Iterators.product([roles1, roles2])))
    Set([MixRecipe(mixn, o, Set(entity_roleset))
        for (mixn, entity_roleset) in enumerate(pairs)])
end