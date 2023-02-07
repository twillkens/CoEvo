export Mix
export stir, getmixes

struct Mix{D <: Domain, O <: ObsConfig, P <: Phenotype}
    rid::UInt64
    domain::D
    obscfg::O
    phenos::Dict{Symbol, P}
end

function Mix(domain::Domain, obscfg::ObsConfig, phenos::Dict{Symbol, <:Phenotype})
    Mix(UInt64(0), domain, obscfg, phenos)
end

function stir(m::Mix)
    stir(m.rid, m.domain, m.obscfg; m.phenos...) 
end

function(r::Recipe)(
    phenodict::Dict{I, P}) where {I <: Ingredient, P <: Phenotype
}
    phenos = Dict([ingred.pcfg.role => phenodict[ingred]
        for ingred in r.ingredients])
    Mix(r.rid, r.domain, r.obscfg, phenos)
end

function getmixes(
    recipes::Set{<:Recipe}, phenodict::Dict{I, P}) where
{I <: Ingredient, P <: Phenotype}
    Set(r(phenodict) for r in recipes)
end