export CoevConfig
export makevets
export interact, archive!

using ..Common
using ..Reproduction
using ..Jobs
using Random
using JLD2
using StableRNGs

struct CoevConfig{J <: JobConfig, O <: Order, S <: Spawner, L <: Logger}
    eco::Symbol
    trial::Int
    evostate::EvoState
    jobcfg::J
    orders::Dict{Symbol, O}
    spawners::Dict{Symbol, S}
    loggers::Vector{L}
    jld2path::String
    arxiv_interval::Int
    species_cache::Dict{Int, Dict{Symbol, Species}}
    log_interval::Int
end

function CoevConfig(;
    eco::Symbol,
    trial::Int,
    seed::Union{UInt64, Int},
    jobcfg::JobConfig = SerialPhenoJobConfig(),
    orders::Vector{<:Order},
    spawners::Vector{<:Spawner},
    loggers::Vector{<:Logger} = Vector{Logger}(), 
    arxiv_interval::Int = 1,
    log_interval::Int = 100,
    data_dir::String = ENV["DATA_DIR"],
)
    if arxiv_interval > 0
        ecodir = mkpath(joinpath(data_dir, string(eco)))
        jld2path = joinpath(ecodir, "$(trial).jld2")
        jld2file = jldopen(jld2path, "w")
        jld2file["eco"] = eco
        jld2file["trial"] = trial
        jld2file["seed"] = seed
        jld2file["jobcfg"] = jobcfg
        jld2file["orders"] = orders
        jld2file["spawners"] = deepcopy(spawners)
        jld2file["loggers"] = loggers
        jld2file["arxiv_interval"] = arxiv_interval
        jld2file["log_interval"] = log_interval
        JLD2.Group(jld2file, "arxiv")
        close(jld2file)
    else
        jld2path = ""
    end
    orders = Dict(order.oid => order for order in orders)
    spawners = Dict(spawner.spid => spawner for spawner in values(spawners))
    rng = StableRNG(seed)
    evostate = EvoState(rng, collect(keys(spawners)))
    CoevConfig(
        eco, trial, evostate, jobcfg, orders, spawners, loggers, jld2path, arxiv_interval,
        Dict{Int, Dict{Symbol, Species}}(), log_interval,
    )
end

function makeresdict(outcomes::Vector{Outcome{R, O}}) where {R <: Real, O <: Observation}
    resdict = Dict{IndivKey, Vector{Pair{TestKey, R}}}()
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
    indivs::Dict{IndivKey, I}, resdict::Dict{IndivKey, Vector{Pair{TestKey, R}}}
) where {I <: Individual, R <: Real}
    checkd = ikey -> ikey in keys(resdict) ? Dict(resdict[ikey]) : Dict{TestKey, R}()
    VeteranIndiv[VeteranIndiv(indiv.ikey, indiv.geno, indiv.pid, checkd(indiv.ikey)) for indiv in values(indivs)]
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
    gen::Int, c::CoevConfig, allsp::Dict{Symbol, <:Species},
)
    if c.arxiv_interval == 0
        return
    end
    push!(c.spchache, gen => allsp)
    if gen % c.arxiv_interval == 0
        jld2file = jldopen(c.jld2path, "a")
        for (gen, allsp) in c.spchache
            agroup = make_group!(jld2file["arxiv"], string(gen))
            agroup["evostate"] = deepcopy(c.evostate)
            allspgroup = make_group!(agroup, "species")
            [spawner.archiver(allspgroup, allsp[spid]) for (spid, spawner) in c.spawners]
        end
        close(jld2file)
        println("done archiving: $(c.trial), gen : $gen")
        empty!(c.spchache)
        GC.gc()
    end
end

# Default evolutionary loop. Takes in a generation number and a dict of species and 
# produces the next generation of species and filling the JLD2 archive for the trial.
function(c::CoevConfig)(gen::Int, allsp::Dict{Symbol, <:Species})
    # If we have reached a logging interval, log the times taken to perform
    # each step of the coevolutionary GA (archiving previous generation, 
    # performing interactions, an spawning new species)
    if c.log_interval > 0 && gen % c.log_interval == 0
        t = time()
        archive!(gen, c, allsp)
        atime = time() - t
        t = time()
        allvets, outcomes = interact(c, allsp)
        itime = time() - t
        t = time()
        nextsp = Dict(
            spawner.spid => spawner(c.evostate, allvets) for spawner in values(c.spawners)
        )
        stime = time() - t
        println("trial: $(c.trial) gen: $gen, archive: $atime, interact: $itime, spawn: $stime")
        nextsp
    else
        # Otherwise we perform the operations silently
        archive!(gen, c, allsp)
        allvets, outcomes = interact(c, allsp)
        nextsp = Dict(
            spawner.spid => spawner(c.evostate, allvets) for spawner in values(c.spawners)
        )
        nextsp
    end
end

# Generate a dictionary of species from a CoevConfig
# Each species is generated by its respective spawner, with a population of organisms
# 
function(c::CoevConfig)()::Dict{Symbol, <:Species}
    allsp = Dict(spawner.spid => spawner(c.evostate) for spawner in values(c.spawners))
    allsp
end