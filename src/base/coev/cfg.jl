export CoevConfig
export makevets
export interact, archive!

struct CoevConfig{O <: Order, S <: Spawner, L <: Logger}
    key::String
    trial::Int
    rng::AbstractRNG
    jobcfg::JobConfig
    orders::Dict{Symbol, O}
    spawners::Dict{Symbol, S}
    loggers::Vector{L}
    jld2file::JLD2.JLDFile
end


function CoevConfig(;
    key::String,
    trial::Int,
    seed::UInt64,
    rng::AbstractRNG,
    jobcfg::JobConfig, 
    orders::Dict{Symbol, <:Order},
    spawners::Dict{Symbol, <:Spawner},
    loggers::Vector{<:Logger},
    logpath::String = "log.jld2",
)
    jld2file = jldopen(logpath, "w")
    jld2file["key"] = key
    jld2file["trial"] = trial
    jld2file["seed"] = seed
    jld2file["jobcfg"] = jobcfg
    jld2file["orders"] = orders
    jld2file["spawners"] = deepcopy(spawners)
    jld2file["loggers"] = loggers
    JLD2.Group(jld2file, "gens")
    CoevConfig(key, trial, rng, jobcfg, orders, spawners, loggers, jld2file)
end

function makeresdict(outcomes::Vector{<:Outcome})
    resdict = Dict{IndivKey, Vector{Pair{TestKey, <:Real}}}()
    for outcome in outcomes
        for (ikey, pair) in outcome.rdict
            if ikey in keys(resdict)
                push!(resdict[ikey], pair)
            else
                resdict[ikey] = [pair]
            end
        end
    end
    resdict
end

function makevets(
    indivs::Dict{IndivKey, I}, resdict::Dict{IndivKey, Vector{Pair{TestKey, <:Real}}}
) where {I <: Individual}
    checkd = ikey -> ikey in keys(resdict) ? Dict(resdict[ikey]) : Dict{TestKey, <:Real}()
    Veteran[Veteran(indiv.ikey, indiv, checkd(indiv.ikey)) for indiv in values(indivs)]
end

function makevets(allsp::Dict{Symbol, <:Species}, outcomes::Vector{<:Outcome})
    resdict = makeresdict(outcomes)
    Dict(spid => 
        Species(
            spid,
            sp.phenocfg,
            makevets(sp.pop, resdict),
            makevets(sp.children, resdict))
    for (spid, sp) in allsp)
end

function interact(c::CoevConfig, allsp::Dict{Symbol, <:Species})
    recipes = makerecipes(c.orders, allsp)
    work = c.jobcfg(allsp, c.orders, recipes)
    outcomes = perform(work)
    makevets(allsp, outcomes), outcomes
end

function archive!(
    gen::UInt16, c::CoevConfig, allvets::Dict{Symbol, <:Species{<:Veteran}},
    outcomes::Vector{<:Outcome}
)
    ggroup = JLD2.Group(c.jld2file["gens"], string(gen))
    ggroup["rng"] = c.rng
    [logger(gen, ggroup, allvets, outcomes) for logger in c.loggers]
end

function(c::CoevConfig)(gen::UInt16, allsp::Dict{Symbol, <:Species})
    allvets, outcomes = interact(c, allsp)
    archive!(gen, c, allvets, outcomes)
    Dict(spawner.spid => spawner(allvets) for spawner in values(c.spawners))
end

function(c::CoevConfig)()
    Dict(spawner.spid => spawner() for spawner in values(c.spawners))
end


