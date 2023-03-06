export FitnessLogger
export BasicGeneLogger
export StatFeatures
export SpeciesLogger

Base.@kwdef struct StatFeatures
    sum::Float64 = 0
    mean::Float64 = 0
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
        StatFeatures(
            sum = sum(vec),
            mean = mean(vec),
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

function StatFeatures(vec::Vector{StatFeatures}, field::Symbol)
    StatFeatures([getfield(sf, field) for sf in vec])
end

function make_group!(parent_group::JLD2.Group, key::String)
    key ∉ keys(parent_group) ? JLD2.Group(parent_group, key) : parent_group[key]
end

function make_group!(parent_group::JLD2.Group, key::Union{Symbol, UInt32, Int})
    make_group!(parent_group, string(key))
end

function(a::Archiver)(::Int, allspgroup::JLD2.Group, spid::Symbol, sp::Species)
    spgroup = make_group!(allspgroup, string(spid))
    spgroup["popids"] = a.log_popids ? [ikey.iid for ikey in keys(sp.pop)] : UInt32[]
    cngroup = make_group!(spgroup, "children")
    for indiv in values(sp.children)
        a(cngroup, indiv)
    end
end