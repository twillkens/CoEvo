export Mix
export stir, getmixes

struct Mix{D <: Domain, O <: ObsConfig, P <: Phenotype}
    rid::Int
    domain::D
    obscfg::O
    phenos::Dict{Symbol, P}
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

function getmixes(recipes::Set{<:Recipe},
                  genodict::Dict{String, Genotype},)
    phenodict = makephenodict(recipes, genodict)
    getmixes(recipes, phenodict)
end