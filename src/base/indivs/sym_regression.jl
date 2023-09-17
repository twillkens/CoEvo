export VectorIndiv, VectorGeno
export make_genotype
export ScalarGene
export VectorIndivConfig, VectorIndivArchiver
export genotype, clone, getgids, getvals


struct SymbolicRegressionTestIndiv{G <: ScalarGene} <: Individual
    ikey::IndivKey
    point::Float64
    func::Function
end

Base.@kwdef struct SymbolicRegressionTestIndivConfig <: IndivConfig
    spid::Symbol
    point_range::UnitRange{Int}
    func::Function
end

# Archiver for SymbolicRegressionTestIndiv
# Stores the point and func of each individual
Base.@kwdef struct SymbolicRegressionTestIndivArchiver <: Archiver end

function(a::SymbolicRegressionTestIndivArchiver)(
    children_group::JLD2.Group, child::SymbolicRegressionTestIndiv,
)
    cgroup = make_group!(children_group, child.iid)
    cgroup["point"] = child.point
    cgroup["func"] = child.func
end

# Load function for SymbolicRegressionTestIndiv from archive
function(cfg::SymbolicRegressionTestIndivArchiver)(spid::String, iid::String, igroup::JLD2.Group)
    point = igroup["point"]
    func = igroup["func"]
    SymbolicRegressionTestIndiv(IndivKey(spid, iid), point, func)
end

function(cfg::VectorIndivConfig)(::AbstractRNG, sc::SpawnCounter, n_indiv::Int, val::Real)
    indivs = [
        VectorIndiv(
            cfg.spid, iid!(sc), gids!(sc, cfg.width), fill(val, cfg.width)
        ) for _ in 1:n_indiv
    ]
    Dict(indiv.ikey => indiv for indiv in indivs)
end