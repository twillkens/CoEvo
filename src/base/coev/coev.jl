export CoevConfig
export makevets

struct CoevConfig{O <: Order, S <: Spawner, L <: Logger}
    key::String
    trial::Int
    rng::AbstractRNG
    job_cfg::JobConfig
    orders::Set{O}
    spawners::Set{S}
    loggers::Set{L}
    jld2file::JLD2.JLDFile
end

function CoevConfig(;
        key::String,
        trial::Int,
        job_cfg::JobConfig, 
        orders::Set{<:Order},
        spawners::Set{<:Spawner},
        loggers::Set{<:Logger},
        logpath::String = "log.jld2",
        seed::UInt64 = rand(UInt64)
        )
    jld2file = jldopen(logpath, "w")
    jld2file["key"] = key
    jld2file["trial"] = trial
    jld2file["seed"] = seed
    rng = StableRNG(seed)
    CoevConfig(key, trial, rng, job_cfg, orders, spawners, loggers, jld2file)
end

function make_indivdict(sp::Species)
    Dict(indiv.iid => indiv for indiv in union(sp.pop, sp.children))
end

function makevets(indivs::Set{<:Individual}, allresults::Set{<:Result})
    Set(Veteran(indiv,
        filter(r -> r.spkey == indiv.spkey && r.iid == indiv.iid, allresults))
    for indiv in indivs)
end

function makevets(indivs::Set{<:Individual}, outcomes::Set{<:Outcome})
    results = union([o.results for o in outcomes]...)
    makevets(indivs, results)
end

function makevets(allsp::Set{<:Species}, outcomes::Set{<:Outcome})
    results = union([o.results for o in outcomes]...)
    Dict(sp.spkey => Species(
        sp.spkey,
        makevets(sp.pop, results),
        Int[i.iid for i in sp.parents],
        makevets(sp.children, results))
    for sp in allsp)
end

function checkcache(cache::Dict{Recipe, Outcome}, recipes::Set{<:Recipe})
    cache = filter(((k,v),) -> k ∈ recipes, cache)
    for r in recipes
        if r in keys(cache)

        end
    end
end

function(c::CoevConfig)(gen::Int, allsp::Set{<:Species})
    recipes = makerecipes(c.orders, allsp)

    work = c.job_cfg(recipes, allsp)
    outcomes = perform(work)
    allvets = makevets(allsp, outcomes)
    gen_species = JLD2.Group(c.jld2file, string(gen))
    gen_species["rng"] = copy(c.rng)
    [logger(gen_species, allvets) for logger in c.loggers]
    Set(spawner(gen, allvets[spawner.spkey]) for spawner in c.spawners)
end
