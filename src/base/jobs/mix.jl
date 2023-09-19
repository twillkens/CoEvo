export Mix
export stir, getmixes

struct Mix{D <: Domain, O <: ObsConfig, P <: Phenotype}
    oid::Symbol # ID of the order that generated this mix
    domain::D # Interactive domain
    obscfg::O # Configuration used to create the Observation result upon evaluation
    phenos::Vector{P} # Vector of individual phenotypes
end


function(r::Recipe)(order::Order, phenodict::Dict)
    phenos = [phenodict[ikey.spid][ikey.iid] for ikey in r.ikeys]
    Mix(r.oid, order.domain, order.obscfg, phenos)
end

function getmixes(
    odict::Dict{Symbol, <:Order},
    phenodict::Dict,
    recipes::Vector{<:Recipe}
)
    [r(odict[r.oid], phenodict) for r in recipes]
end

function getmixes(job::PhenoJob)
    getmixes(job.odict, job.phenodict, job.recipes)
end

function stir(m::Mix)
    stir(m.oid, m.domain, m.obscfg, m.phenos...) 
end