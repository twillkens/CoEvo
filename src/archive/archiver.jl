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