
function append_stats_to_csv(pop)
    fits = [fitness(vet) for vet in pop]
    full_genos = [length(merge(i.geno.funcs, i.geno.terms)) for i in pop]
    pruned_genos = [pruned_size(geno.geno) for geno in pop]
    spid = pop[1].ikey.spid
    filename = "$spid.csv"
    
    # Calculate stats
    full_stats = (
        category="Full Geno Stats", 
        min=round(minimum(full_genos), digits=2), 
        max=round(maximum(full_genos), digits=2), 
        mean=round(mean(full_genos), digits=2), 
        median=round(median(full_genos), digits=2), 
        std=round(std(full_genos), digits=2)
    )
    pruned_stats = (
        category="Pruned Geno Stats",
        min=round(minimum(pruned_genos), digits=2), 
        max=round(maximum(pruned_genos), digits=2), 
        mean=round(mean(pruned_genos), digits=2), 
        median=round(median(pruned_genos), digits=2), 
        std=round(std(pruned_genos), digits=2)
    )
    fits_stats = (category="Fitness Stats", min=round(minimum(fits), digits=2), max=round(maximum(fits), digits=2), mean=round(mean(fits), digits=2), median=round(median(fits), digits=2), std=round(std(fits), digits=2))

    # Check if file exists
    if isfile(filename)
        df = CSV.File(filename) |> DataFrame
    else
        df = DataFrame(
            category=String[],
            min=Float64[],
            max=Float64[],
            mean=Float64[],
            median=Float64[],
            std=Float64[]
        )
    end

    # Append stats to dataframe
    push!(df, full_stats)
    push!(df, pruned_stats)
    push!(df, fits_stats)

    # Write to CSV
    CSV.write(filename, df, append=false)  # Overwrite the file with updated DataFrame
end



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
                spawners[Symbol(spid)].phenocfg,
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
    jobcfg = jld2file["jobcfg"]
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
            eco, trial, evostate, jobcfg, orders, spawners, loggers, 
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



export make_group!
export NullArchiver

# Utility function for creating a JLD2 group if it doesn't exist
# and returning group if it does
function make_group!(parent_group::JLD2.Group, key::String)
    key ∉ keys(parent_group) ? JLD2.Group(parent_group, key) : parent_group[key]
end

function make_group!(parent_group::JLD2.Group, key::Union{Symbol, UInt32, Int})
    make_group!(parent_group, string(key))
end

# Save an individual to a JLD2.Group
function(a::Archiver)(
    children_group::JLD2.Group, child::Individual,
)
    child_group = make_group!(children_group, child.iid)
    child_group["pid"] = child.pid
    geno_group = make_group!(cgroup, "geno")
    a(geno_group, child.geno)
end

# Load an individual from a JLD2.Group given its spid and iid
function(a::Archiver)(spid::Symbol, iid::Int, igroup::JLD2.Group)
    pid = igroup["pid"]
    geno = a(igroup["geno"])
    BasicIndiv(IndivKey(spid, iid), geno, pid)
end

function(a::Archiver)(spid::String, iid::String, igroup::JLD2.Group)
    a(Symbol(spid), parse(Int, iid), igroup)
end

function(a::Archiver)(all_species_group::JLD2.Group, sp::Species)
    species_group = make_group!(all_species_group, string(sp.spid))
    species_group["popids"] = [ikey.iid for ikey in keys(sp.pop)]
    children_group = make_group!(spgroup, "children")
    for child in values(sp.children)
        a(children_group, child)
    end
end

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

function(a::JLD2Archivist)(archive_path::String)
    a.archive(archive_path, allsp)
end

Base.@kwdef struct StatFeatures
    sum::Float64 = 0
    upper_confidence = 0
    mean::Float64 = 0
    lower_confidence = 0
    variance::Float64 = 0
    std::Float64 = 0
    minimum::Float64 = 0
    lower_quartile::Float64 = 0
    median::Float64 = 0
    upper_quartile::Float64 = 0
    maximum::Float64 = 0
end

function StatFeatures(vec::Vector{<:Real})
    if length(vec) == 0
        StatFeatures()
    else
        min_, lower_, med_, upper_, max_, = nquantile(vec, 4)
        loconf, hiconf = confint(OneSampleTTest(vec))
        StatFeatures(
            sum = sum(vec),
            lower_confidence = loconf,
            mean = mean(vec),
            upper_confidence = hiconf,
            variance = var(vec),
            std = std(vec),
            minimum = min_,
            lower_quartile = lower_,
            median = med_,
            upper_quartile = upper_,
            maximum = max_,
        )
    end
end



function StatFeatures(tup::Tuple{Vararg{<:Real}})
    StatFeatures(collect(tup))
end

function StatFeatures(vec::Vector{StatFeatures}, field::Symbol)
    StatFeatures([getfield(sf, field) for sf in vec])
end

