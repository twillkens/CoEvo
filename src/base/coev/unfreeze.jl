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
    jld2file::JLD2.JLDFile, spawners::Dict{Symbol, <:Spawner}, getpop::Bool = true
)
    arxivgroup = jld2file["arxiv"]
    currgen = keys(arxivgroup)[end]
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
        push!(sppairs, 
            Symbol(spid) => Species(
                Symbol(spid),
                spawners[Symbol(spid)].phenocfg,
                pop, 
                children
            )
        )
    end
    parse(Int, currgen) + 1, evostate, Dict(sppairs...)
end

function unfreeze(jldpath::String, getpop::Bool = true)
    jld2file = jldopen(jldpath, "a")
    eco = jld2file["eco"]
    trial = jld2file["trial"]
    jobcfg = jld2file["jobcfg"]
    orders = jld2file["orders"]
    spawners = jld2file["spawners"]
    loggers = jld2file["loggers"]
    gen, evostate, allsp = unfreeze(jld2file, spawners, getpop)
    close(jld2file)
    gen, CoevConfig(eco, trial, evostate, jobcfg, orders, spawners, loggers, jldpath), allsp
end
