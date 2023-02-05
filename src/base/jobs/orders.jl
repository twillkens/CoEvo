export AllvsAllOrder, getroles
export PopRole, IndivRole, Recipe

function getroles(o::Order, sp::Species) 
    return [IndivRole(indiv.geno, o.roles[sp.key])
    for indiv in union(sp.pop, sp.children)]
end

Base.@kwdef struct AllvsAllOrder{D <: Domain, O <: ObsConfig, P <: PhenoConfig} <: Order
    domain::D
    obscfg::O
    roles::Dict{String, PopRole{P}}
end

function(o::AllvsAllOrder)(sp1::Species, sp2::Species)
    roles1 = getroles(o, sp1)
    roles2 = getroles(o, sp2)
    pairs = unique(Set, Iterators.filter(allunique,
                   Iterators.product([roles1, roles2])))
    Set([Recipe(mixn, o, Set(entity_roleset))
        for (mixn, entity_roleset) in enumerate(pairs)])
end