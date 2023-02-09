export Job
export SerialJobConfig, ParallelJobConfig
export perform

export makerecipes, makegenodict, makephenodict

struct Job{R <: Recipe, G <: Genotype, O <: Order}
    orders::Dict{Symbol, O}
    recipes::Set{R}
    genodict::Dict{IndivKey, G}
end

function makerecipes(orders::Set{<:Order}, allsp::Set{<:Species})
    union([order(allsp) for order in orders]...)
end

function makeallgenos(allsp::Set{<:Species})
    Dict(indiv.ikey => genotype(indiv) for indiv in allindivs(allsp))
end

function makegenodict(
    allgenos::Dict{IndivKey, G},
    recipes::Set{<:Recipe}) where {G <: Genotype
}
    Dict(ikey => allgenos[ikey] for ikey in getikeys(recipes))
end


function getphenocfg(odict::Dict{Symbol, <:Order}, ingredkey::IngredientKey)
    odict[ingredkey.oid].phenocfgs[ingredkey.spid]
end

function makephenodict(
    orders::Set{<:Order}, recipes::Set{<:Recipe},
    genodict::Dict{IndivKey, G}) where {G <: Genotype
}
    odict = Dict(order.oid => order for order in orders)
    phenopairs = Pair[]
    for ingredkey in getingredkeys(recipes)
        phenocfg = getphenocfg(odict, recipe)
        pheno = phenocfg(genodict[ingredkey.ikey])
        push!(phenopairs, ingredkey => pheno)
    end
    Dict(phenopairs)
end

function makephenodict(job::Job)
    makephenodict(job.orders, job.recipes, job.genodict)
end


function getmixes(job::Job, phenodict::Dict{I, P}) where
{I <: IngredientKey, P <: Phenotype}
    odict = Dict(order.oid => order for order in job.orders)
    Set(r(odict[r.oid], phenodict) for r in job.recipes)
end

function perform(job::Job)
    phenodict = makephenodict(job)
    mixes = getmixes(job, phenodict)
    Set(stir(mix) for mix in mixes)
end

function perform(jobs::Set{<:Job})
    futures = [remotecall(perform, i, job) for (i, job) in enumerate(jobs)]
    outcomes = [fetch(f) for f in futures]
    union(outcomes...)
end

struct SerialJobConfig <: JobConfig end

function(cfg::SerialJobConfig)(
    allsp::Set{<:Species}, orders::Set{<:Order}, recipes::Set{<:Recipe}
)
    allgenos = makeallgenos(allsp)
    genodict = makegenodict(allgenos, recipes)
    Job(orders, recipes, genodict)
end

Base.@kwdef struct ParallelJobConfig <: JobConfig
    n_jobs::Int
end

function divvy(recipes::Set{<:Recipe}, n_subsets::Int)
    n_mix = div(length(recipes), n_subsets)
    recipe_vecs = collect(Iterators.partition(collect(recipes), n_mix))
    # If there are leftovers, divide the excess among the other subsets
    if length(recipe_vecs) > n_subsets
        excess = pop!(recipe_vecs)
        for i in eachindex(excess)
            push!(recipe_vecs[i], excess[i])
        end
    end
    Set(Set(rvec) for rvec in recipe_vecs)
end

function(cfg::ParallelJobConfig)(
    allsp::Set{<:Species}, orders::Set{<:Order}, recipes::Set{<:Recipe}
)
    allgenos = makeallgenos(allsp)
    rsets = divvy(recipes, cfg.n_jobs)
    Set(Job(orders, recipes, makegenodict(allgenos, recipes)) for recipes in rsets)
end
