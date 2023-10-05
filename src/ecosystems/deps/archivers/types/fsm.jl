module FSMSubstrate

export FSMIndiv, FiniteStateMachineGenotype, Phenotype, FSMPhenoCfg
export genotype, LinkDict, StateSet, act, FSMIndivConfig
export Archiver, FSMSetPheno, FiniteStateMachinePhenotype

LinkDict = Dict{Tuple{String, Bool}, String}
StateSet = Set{String}



# Phenotype






Base.@kwdef struct Archiver <: Archiver
end

# Save an genotype to a JLD2.Group
function(a::Archiver)(geno_group::JLD2.Group, geno::FiniteStateMachineGenotype)
    geno_group["start"] = geno.start
    geno_group["ones"] = collect(geno.ones)
    geno_group["zeros"] = collect(geno.zeros)
    geno_group["sources"] = [source for ((source, _), _) in geno.links]
    geno_group["bits"] = [bit for ((_, bit), _) in geno.links]
    geno_group["targets"] = [target for ((_, _), target) in geno.links]
end

# Save an individual to a JLD2.Group
function(a::Archiver)(
    children_group::JLD2.Group, child::FSMIndiv,
)
    cgroup = make_group!(children_group, child.iid)
    cgroup["pids"] = child.pids
    geno_group = make_group!(cgroup, "geno")
    a(geno_group, child.geno)
end

# Load a genotype from a JLD2.Group
function(a::Archiver)(geno_group::JLD2.Group)
    start = geno_group["start"]
    ones = Set(geno_group["ones"])
    zeros = Set(geno_group["zeros"])
    links = Dict(
        (s, b) => t for (s, b, t) in
        zip(geno_group["sources"], geno_group["bits"], geno_group["targets"])
    )
    FiniteStateMachineGenotype(start, ones, zeros, links)
end


# Load an individual from a JLD2.Group given its spid and iid
function(a::Archiver)(spid::Symbol, iid::UInt32, igroup::JLD2.Group)
    pids = igroup["pids"]
    geno = a(igroup["geno"])
    FSMIndiv(spid, iid, geno, pids)
end

function(a::Archiver)(spid::String, iid::String, igroup::JLD2.Group)
    a(Symbol(spid), parse(UInt32, iid), igroup)
end

function(cfg::IndivConfig)(spid::String, iid::String, igroup::JLD2.Group)
    cfg(Symbol(spid), parse(UInt32, iid), igroup)
end

end