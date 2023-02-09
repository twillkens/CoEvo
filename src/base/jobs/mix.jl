export Mix
export stir, getmixes

struct Mix{D <: Domain, O <: ObsConfig, P <: Phenotype}
    domain::D
    obscfg::O
    phenos::Dict{Symbol, P}
end

function Mix(domain::Domain, obscfg::ObsConfig, phenos::Dict{Symbol, <:Phenotype})
    Mix(domain, obscfg, phenos)
end

function stir(m::Mix)
    stir(m.rid, m.domain, m.obscfg; m.phenos...) 
end

function getrole(order::Order, ingred::IngredientKey)
    order.phenocfgs[ingred.spid].role
end

function(r::Recipe)(order::Order, phenodict::Dict{I, P}) where
{I <: IngredientKey, P <: Phenotype}
    phenos = Dict(getrole(order, ingred) => phenodict[ingred]
        for ingred in getingredkeys(r))
    Mix(order.domain, order.obscfg, phenos)
end
