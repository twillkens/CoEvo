export Mix
export stir, getmixes

struct Mix{D <: Domain, O <: ObsConfig, P <: Phenotype}
    oid::Symbol
    domain::D
    obscfg::O
    phenos::Vector{P}
end

function(r::Recipe)(order::Order, phenodict::Dict{Symbol, Dict{UInt32, P}}) where P
    phenos = [phenodict[ikey.spid][ikey.iid] for ikey in r.ikeys]
    Mix(r.oid, order.domain, order.obscfg, phenos)
end

function getmixes(
    odict::Dict{Symbol, <:Order},
    phenodict::Dict{Symbol, Dict{UInt32, P}},
    recipes::Vector{<:Recipe}
)  where P
    [r(odict[r.oid], phenodict) for r in recipes]
end

function getmixes(job::PhenoJob)
    getmixes(job.odict, job.phenodict, job.recipes)
end

function stir(m::Mix)
    stir(m.oid, m.domain, m.obscfg, m.phenos...) 
end