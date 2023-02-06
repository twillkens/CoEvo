export SerialJob, SerialJobConfig
export perform

struct SerialJob <: Job
    recipes::Set{Recipe}
    genodict::Dict{String, Dict{Int, Genotype}}
end

struct SerialJobConfig <: JobConfig end

function makegenodict(allsp::Set{<:Species})
    Dict([sp.spkey => Dict([indiv.iid => genotype(indiv)
        for indiv in union(sp.pop, sp.children)])
        for sp in allsp])
end

function makephenodict(
    recipes::Set{<:Recipe}, genodict::Dict{String, Dict{Int, G}}
    where {G <: Genotype}
)
    ingredients = union([recipe.ingredients for recipe in recipes]...)
    Dict([ingred => ingred.pcfg(genodict[ingred.spkey][ingred.iid])
        for ingred in ingredients])
end

function makerecipes(orders::Set{<:Order}, allsp::Set{<:Species})
    union([order(allsp) for order in orders]...)
end

function(cfg::SerialJobConfig)(orders::Set{<:Order}, allsp::Set{<:Species})
    recipes = makerecipes(orders, allsp)
    genodict = makegenodict(allsp)
    SerialJob(recipes, genodict,)
end

function perform(job::SerialJob)
    phenodict = makephenodict(job.recipes, job.genodict)
    mixes = getmixes(job.recipes, phenodict)
    Set([stir(mix) for mix in mixes])
end