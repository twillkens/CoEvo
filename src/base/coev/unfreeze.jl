export unfreeze

function findpop(
    gen::Int,
    spid::String,
    jld2file::JLD2.JLDFile,
    icfg::IndivConfig,
    popids::Vector{String}, 
    pop::Vector{<:Individual} = Individual[]
)
    if length(popids) == 0
        return pop
    elseif gen == 0
        throw(ArgumentError("Could not find all popids in the population."))
    end
    childrengroup = jld2file["gens"][string(gen)]["species"][spid]["children"]
    for iid in popids
        if iid in keys(childrengroup)
            push!(pop, icfg(spid, iid, childrengroup[iid]))
            filter!(x -> x != iid, popids)
        end
    end
    println(popids)
    findpop(gen - 1, spid, jld2file, icfg, popids, pop)
end

function unfreeze(
    jld2file::JLD2.JLDFile, spawners::Dict{Symbol, <:Spawner}, getpop::Bool = false
)
    allggroup = jld2file["gens"]
    currgen = keys(allggroup)[end]
    ggroup = allggroup[currgen]
    evostate = ggroup["evostate"]
    allspgroup = ggroup["species"]
    sppairs = Pair{Symbol, <:Species}[]
    for spid in keys(allspgroup)
        spgroup = allspgroup[spid]
        icfg = spawners[Symbol(spid)].icfg
        popids = spgroup["popids"]
        pop = getpop ? findpop(
            parse(Int, currgen) - 1,
            spid,
            jld2file,
            icfg,
            string.(popids),
            icfg.itype[]
        ) : Individual[]
        childrengroup = spgroup["children"]
        children = [icfg(spid, iid, childrengroup[iid]) for iid in keys(childrengroup)]
        push!(sppairs, 
            Symbol(spid) => Species(
                Symbol(spid),
                spawners[Symbol(spid)].phenocfg,
                pop, 
                children
            )
        )
    end
    evostate, parse(Int, currgen) + 1, Dict(sppairs...)
end

function unfreeze(jldpath::String)
    jld2file = jldopen(jldpath, "a")
    key = jld2file["key"]
    trial = jld2file["trial"]
    jobcfg = jld2file["jobcfg"]
    orders = jld2file["orders"]
    spawners = jld2file["spawners"]
    loggers = jld2file["loggers"]
    evostate, gen, sp = unfreeze(jld2file, spawners)
    CoevConfig(key, trial, evostate, jobcfg, orders, spawners, loggers, jld2file), gen, sp
end
