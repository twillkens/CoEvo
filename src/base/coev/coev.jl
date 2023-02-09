export CoevConfig
export makevets

struct CoevConfig{O <: Order, S <: Spawner, L <: Logger}
    key::String
    trial::Int
    rng::AbstractRNG
    jobcfg::JobConfig
    orders::Set{O}
    spawners::Set{S}
    loggers::Set{L}
    jld2file::JLD2.JLDFile
    cache::Dict{Recipe, Outcome}
end

function CoevConfig(;
        key::String,
        trial::Int,
        seed::UInt64,
        rng::AbstractRNG,
        jobcfg::JobConfig, 
        orders::Set{<:Order},
        spawners::Set{<:Spawner},
        loggers::Set{<:Logger},
        logpath::String = "log.jld2",
        )
    jld2file = jldopen(logpath, "w")
    jld2file["key"] = key
    jld2file["trial"] = trial
    jld2file["seed"] = seed
    CoevConfig(key, trial, rng, jobcfg, orders, spawners,
        loggers, jld2file, Dict{UInt64, Outcome}())
end

function make_indivdict(sp::Species)
    Dict(indiv.iid => indiv for indiv in union(sp.pop, sp.children))
end

function makevets(indivs::Set{<:Individual}, allresults::Set{<:Result})
    Set(Veteran(indiv,
        filter(r -> r.spid == indiv.spid && r.iid == indiv.iid, allresults))
    for indiv in indivs)
end

function makevets(indivs::Set{<:Individual}, outcomes::Set{<:Outcome})
    results = union([o.results for o in outcomes]...)
    makevets(indivs, results)
end

function makevets(allsp::Set{<:Species}, outcomes::Set{<:Outcome})
    results = union([o.results for o in outcomes]...)
    Set(Species(
        sp.spid,
        makevets(sp.pop, results),
        sp.parents,
        makevets(sp.children, results))
    for sp in allsp)
end

function prune!(cache::Dict{Recipe, Outcome}, recipes::Set{<:Recipe})
    filter!(((oldr, _),) -> oldr ∈ recipes, cache)
    filter(newr -> newr ∉ keys(cache), recipes), Set(values(cache))
end

function update!(cache::Dict{UInt64, Outcome}, outcomes::Set{<:Outcome})
    merge!(cache, Dict(o.recipe => o for o in outcomes))
end

function(c::CoevConfig)(gen::UInt16, allsp::Set{<:Species})
    recipes = makerecipes(c.orders, allsp)
    work_recipes, cached_outcomes = prune!(c.cache, recipes)
    println("cache: ", length(cached_outcomes))
    work = c.jobcfg(allsp, work_recipes)
    work_outcomes = perform(work)
    println("work: ", length(work_outcomes))
    update!(c.cache, work_outcomes)
    outcomes = union(cached_outcomes, work_outcomes)
    allvets = makevets(allsp, outcomes)
    gen_species = JLD2.Group(c.jld2file, string(gen))
    gen_species["rng"] = copy(c.rng)
    obs = Set(o.obs for o in outcomes)
    [logger(c.jld2file, allvets, obs) for logger in c.loggers]
    Set(spawner(gen, allvets) for spawner in c.spawners)
end

function(c::CoevConfig)()
    Set(spawner() for spawner in c.spawners)
end



