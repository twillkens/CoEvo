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