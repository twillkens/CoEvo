export Mix
export stir, getmixes

struct Mix{D <: Domain, O <: ObsConfig, P <: Phenotype}
    oid::Symbol
    domain::D
    obscfg::O
    roledict::Dict{Symbol, P}
end

function stir(m::Mix)
    stir(m.oid, m.domain, m.obscfg; m.roledict...) 
end

function getrole(order::Order, ingred::IngredientKey)
    order.phenocfgs[ingred.spid].role
end

function(r::Recipe)(
    domain::Domain, obscfg::ObsConfig, roledict::Dict{IngredientKey, <:Phenotype}
)
    Mix(r.oid, domain, obscfg, roledict)
end

function(r::Recipe)(order::Order, phenodict::Dict{IngredientKey, <:Phenotype})
    roledict = Dict(getrole(order, ingred) => phenodict[ingred]
        for ingred in getingredkeys(r))
    Mix(r.oid, order.domain, order.obscfg, roledict)
end
