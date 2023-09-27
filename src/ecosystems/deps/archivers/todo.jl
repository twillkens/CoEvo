
export unfreeze

function findpop(
    gen::Int,
    spid::String,
    arxivgroup::JLD2.Group,
    archiver::Archiver,
    popids::Vector{String}, 
    pop::Vector{<:Individual} = Individual[]
)
    if length(popids) == 0
        return pop
    elseif gen == 0
        throw(ArgumentError("Could not find all popids in the population."))
    end
    childrengroup = arxivgroup[string(gen)]["species"][spid]["children"]
    found = Set{String}()
    for iid in popids
        if iid in keys(childrengroup)
            push!(pop, archiver(spid, iid, childrengroup[iid]))
            push!(found, iid)
        end
    end
    filter!(x -> x ∉ found, popids)
    findpop(gen - 1, spid, arxivgroup, archiver, popids, pop)
end

function unfreeze(
    jld2file::JLD2.JLDFile, spawners::Dict{Symbol, <:Spawner},
    getpop::Bool = true, gen::Int = -1
)
    arxivgroup = jld2file["arxiv"]
    currgen = gen == - 1 ? keys(arxivgroup)[end] : string(gen)
    gengroup = arxivgroup[currgen]
    evostate = gengroup["evostate"]
    allspgroup = gengroup["species"]
    sppairs = Pair{Symbol, <:Species}[]
    for spid in keys(allspgroup)
        spgroup = allspgroup[spid]
        archiver = spawners[Symbol(spid)].archiver
        popids = spgroup["popids"]
        pop = getpop ? findpop(
            parse(Int, currgen) - 1,
            spid,
            arxivgroup,
            archiver,
            string.(popids),
        ) : Individual[]
        childrengroup = spgroup["children"]
        children = [archiver(spid, iid, childrengroup[iid]) for iid in keys(childrengroup)]
        push!(
            sppairs, 
            Symbol(spid) => Species(
                Symbol(spid),
                spawners[Symbol(spid)].phenocreator,
                pop, 
                children
            )
        )
    end
    parse(Int, currgen) + 1, evostate, Dict(sppairs...)
end

function unfreeze(jldpath::String, getpop::Bool = true, gen::Int = -1)
    jld2file = jldopen(jldpath, "r")
    eco = jld2file["eco"]
    trial = jld2file["trial"]
    jobcreator = jld2file["jobcreator"]
    orders = jld2file["orders"]
    spawners = jld2file["spawners"]
    loggers = jld2file["loggers"]
    arxiv_interval = jld2file["arxiv_interval"]
    log_interval = jld2file["log_interval"]
    gen, evostate, allsp = unfreeze(jld2file, spawners, getpop, gen)
    close(jld2file)
    (
        gen, 
        CoevConfig(
            eco, trial, evostate, jobcreator, orders, spawners, loggers, 
            jldpath, arxiv_interval, Dict{Int, Dict{Symbol, Species}}(), log_interval
        ),
        allsp
    )
end

function unfreeze(ecopath::String, trial::Int, getpop::Bool, genrange:: UnitRange{Int})
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    spawners = jld2file["spawners"]
    allspvec = [unfreeze(jld2file, spawners, getpop, gen)[3] for gen in genrange]
    close(jld2file)
    allspvec
end



export get_or_make_group!
export NullArchiver


struct NullArchiver <: Archiver end

function(a::NullArchiver)(::JLD2.Group, ::Species)
    return
end
function write_to_archive() # TODO: Define
    if arxiv_interval > 0
        ecodir = mkpath(joinpath(data_dir, string(eco)))
        jld2path = joinpath(ecodir, "$(trial).jld2")
        jld2file = jldopen(jld2path, "w")
        jld2file["eco"] = eco
        jld2file["trial"] = trial
        jld2file["seed"] = seed
        jld2file["jobcreator"] = jobcreator
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
end

