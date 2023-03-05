export CoevConfig
export makevets
export interact, archive!

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
end

function CoevConfig(;
    eco::Symbol,
    trial::Int,
    seed::Union{UInt64, Int},
    jobcfg::JobConfig, 
    orders::Dict{Symbol, <:Order},
    spawners::Dict{Symbol, <:Spawner},
    loggers::Vector{<:Logger} = Vector{Logger}(), 
    arxiv_interval::Int = 1,
)
    ecodir = mkpath(joinpath(ENV["COEVO_DATA_DIR"], string(eco)))
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
    JLD2.Group(jld2file, "arxiv")
    close(jld2file)
    rng = StableRNG(seed)
    evostate = EvoState(rng, collect(keys(spawners)))
    CoevConfig(
        eco, trial, evostate, jobcfg, orders, spawners, loggers, jld2path, arxiv_interval
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
    gen::Int, c::CoevConfig, allsp::Dict{Symbol, <:Species},
)
    jld2file = jldopen(c.jld2path, "a")
    agroup = JLD2.Group(jld2file["arxiv"], string(gen))
    agroup["evostate"] = deepcopy(c.evostate)
    allspgroup = make_group!(agroup, "species")
    [spawner.archiver(gen, allspgroup, spid, allsp[spid]) 
    for (spid, spawner) in c.spawners]
    close(jld2file)
end

function(c::CoevConfig)(gen::Int, allsp::Dict{Symbol, <:Species})
    #println("---------")
    if c.arxiv_interval > 0 && gen % c.arxiv_interval == 0
        # println("arxiv")
        #@time archive!(gen, c, allsp)
        archive!(gen, c, allsp)
    end
    #println("sim")
    #@time allvets, outcomes = interact(c, allsp)
    allvets, outcomes = interact(c, allsp)
    #log!(gen, c, allvets, outcomes)
    #println("spawn")
    #@time nextsp = Dict(
    #    spawner.spid => spawner(c.evostate, allvets) for spawner in values(c.spawners)
    #)
    nextsp = Dict(
        spawner.spid => spawner(c.evostate, allvets) for spawner in values(c.spawners)
    )
    nextsp
end

function(c::CoevConfig)()
    Dict(spawner.spid => spawner(c.evostate) for spawner in values(c.spawners))
end


