export Mix
export stir, getmixes

struct Mix{D <: Domain, O <: ObsConfig, P <: Phenotype}
    oid::Symbol
    domain::D
    obscfg::O
    phenos::Vector{P}
end

function(r::Recipe)(order::Order, phenodict::Dict{IndivKey, <:Phenotype})
    phenos = [phenodict[ikey] for ikey in r.ikeys]
    Mix(r.oid, order.domain, order.obscfg, phenos)
end

function getmixes(
    odict::Dict{Symbol, <:Order}, recipes::Vector{<:Recipe},
    phenodict::Dict{IndivKey, <:Phenotype}
)
    [r(odict[r.oid], phenodict) for r in recipes]
end

function getmixes(job::Job)
    getmixes(job.odict, job.recipes, job.phenodict)
end

function stir(m::Mix)
    stir(m.oid, m.domain, m.obscfg, m.phenos...) 
end