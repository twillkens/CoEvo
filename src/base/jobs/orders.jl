export AllvsAllOrder

Base.@kwdef struct AllvsAllOrder{D <: Domain, O <: ObsConfig, P <: PhenoConfig} <: Order
    oid::Symbol
    domain::D
    obscfg::O
    phenocfgs::Dict{Symbol, P}
end


# function(o::AllvsAllOrder)(sp1::Species, sp2::Species)
#     ikeys1 = [i.ikey for i in allindivs(sp1)]
#     ikeys2 = [i.ikey for i in allindivs(sp2)]
#     ikeypairs = unique(Set, Iterators.filter(allunique,
#                    Iterators.product(ikeys1, ikeys2)))
#     Set(Recipe(o.oid, Set(ikeypair)) for ikeypair in ikeypairs)
#         
# end
function(o::AllvsAllOrder)(sp1::Species, sp2::Species)
    ikeys1 = [i.ikey for i in allindivs(sp1)]
    ikeys2 = [i.ikey for i in allindivs(sp2)]
    ikeypairs = Iterators.product(ikeys1, ikeys2)
    Set(Recipe(o.oid, Set(ikeypair)) for ikeypair in ikeypairs)
        
end

function(o::AllvsAllOrder)(allsp::Set{<:Species})
    osp = filter(sp -> sp.spid ∈ keys(o.phenocfgs), allsp)
    o(osp...)
end
