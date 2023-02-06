export AllvsAllOrder

Base.@kwdef struct AllvsAllOrder{D <: Domain, O <: ObsConfig, P <: PhenoConfig} <: Order
    domain::D
    obscfg::O
    phenocfgs::Dict{String, P}
end

function(o::AllvsAllOrder)(sp1::Species, sp2::Species)
    i1 = ingredients(o, sp1)
    i2 = ingredients(o, sp2)
    ingredpairs = unique(Set, Iterators.filter(allunique,
                   Iterators.product(i1, i2)))
    Set([Recipe(mixn, o, Set(ipair))
        for (mixn, ipair) in enumerate(ingredpairs)])
end

function(o::AllvsAllOrder)(allsp::Set{<:Species})
    osp = filter(sp -> sp.spkey ∈ keys(o.phenocfgs), allsp)
    o(osp...)
end
