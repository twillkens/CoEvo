export VCoevConfig

struct VCoevConfig{O <: Order, S <: Spawner, L <: Logger} <: Config
    key::String
    trial::Int
    rng::AbstractRNG
    job_cfg::JobConfig
    orders::Set{O}
    spawners::Set{S}
    loggers::Set{L}
    jld2file::JLD2.JLDFile
end

function VCoevConfig(;
        key::String,
        trial::Int,
        job_cfg::JobConfig, 
        orders::Set{<:Order},
        spawners::Set{<:Spawner},
        loggers::Set{<:Logger},
        logpath::String = "log.jld2",
        seed::UInt64 = rand(UInt64))
    jld2file = jldopen(logpath, "w")
    jld2file["key"] = key
    jld2file["trial"] = trial
    jld2file["seed"] = seed
    rng = StableRNG(seed)
    VCoevConfig(key, trial, rng, job_cfg, orders, spawners, loggers, jld2file)
end

function make_indivdict(sp::Species)
    Dict([indiv.iid => indiv for indiv in union(sp.pop, sp.children)])
end

function assign_outcomes!(allspecies::Set{Species}, job_outcomes::Set{<:Outcome})
    sp_indiv_dict = Dict([sp.spkey => make_indivdict(sp) for sp in allspecies])
    for o in job_outcomes
        indiv = sp_indiv_dict[o.spkey][o.iid]
        push!(indiv.outcomes, o)
    end
end

function(c::VCoevConfig)(gen::Int, allspecies::Set{<:Species})
    jobs = c.job_cfg(c.orders, allspecies)
    job_outcomes = Set{Outcome}(jobs)
    assign_outcomes!(speciesd, job_outcomes)
    gen_species = JLD2.Group(c.jld2file, string(gen))
    gen_species["rng"] = copy(c.rng)
    [logger(gen_species, speciesd) for logger in c.loggers]
    [spawner(gen, speciesd[spawner.key]) for spawner in c.spawners]
end
