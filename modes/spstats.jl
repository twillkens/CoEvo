export SpeciesStats, EcoStats, FilterResults

struct SpeciesStats
    spid::String
    genostats::Union{ModesStats, Nothing}
    minstats::Union{ModesStats, Nothing}
    modestats::ModesStats
    minfitness::Vector{Float64}
    modefitness::Vector{Float64}
    min_eplen::Vector{Float64}
    mode_eplen::Vector{Float64}
    levdist::Vector{Float64}
end

function SpeciesStats(spid::String, allfindivs::Vector{<:Vector{<:FilterIndiv}})
    println("getting stats for $spid")
    genostats = ModesStats(
        [[findiv.geno for findiv in findivs] 
        for findivs in allfindivs]
    )
    mingenostats = ModesStats(
        [[findiv.mingeno for findiv in findivs] 
        for findivs in allfindivs]
    )
    modestats = ModesStats(
        [[findiv.modegeno for findiv in findivs] 
        for findivs in allfindivs]
    )
    minfitness = [mean([findiv.minfitness for findiv in findivs]) for findivs in allfindivs]
    modefitness = [mean([findiv.modefitness for findiv in findivs]) for findivs in allfindivs]
    min_eplen = [mean([findiv.min_eplen for findiv in findivs]) for findivs in allfindivs]
    mode_eplen = [mean([findiv.mode_eplen for findiv in findivs]) for findivs in allfindivs]
    levdist = [mean([findiv.levdist for findiv in findivs]) for findivs in allfindivs]
    #println("ends of all vecs: $(minfitness[end]), $(modefitness[end]), $(min_eplen[end]), $(mode_eplen[end]), $(levdist[end])")
    SpeciesStats(
        spid, 
        genostats, mingenostats, modestats, 
        minfitness, modefitness, 
        min_eplen, mode_eplen,
        levdist,
    )
end

struct FilterResults{I <: FilterIndiv}
    spid::String
    t::Int
    allfindivs::Vector{Vector{I}}
    stats::SpeciesStats
end

struct EcoStats
    eco::String
    trial::Int
    t::Int
    stats::Union{SpeciesStats, Nothing}
    spstats::Dict{String, SpeciesStats}
end

function EcoStats(
    eco::String, trial::Int, t::Int, fdict::Dict{String, <:FilterResults}
)
    spstats = Dict(spid => fresults.stats for (spid, fresults) in fdict)
    allindivs = [fresults.allfindivs for fresults in values(fdict)]
    allindivs = collect(vcat(y...) for y in zip(allindivs...))
    metastats = SpeciesStats(eco, allindivs)
    EcoStats(
        eco,
        trial,
        t,
        metastats,
        spstats, 
    )
end