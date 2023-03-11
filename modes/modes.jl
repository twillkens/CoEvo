using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using CoEvo
@everywhere using JLD2
@everywhere using StatsBase
@everywhere using DataFrames
@everywhere using StableRNGs
@everywhere using Random
@everywhere using DataStructures
@everywhere using StringDistances
@everywhere using Serialization
@everywhere include("abstract.jl")
@everywhere include("util.jl")
@everywhere include("filterindiv.jl")
@everywhere include("koprune.jl")
@everywhere include("bftprune.jl")
@everywhere include("ageprune.jl")
@everywhere include("mstats.jl")
@everywhere include("spstats.jl")
@everywhere include("ptags.jl")
@everywhere include("pfilter.jl")


# get meaningful sites for each persistent individual


function domodes(
    eco::String, 
    trials::UnitRange{Int},
    t::Int,
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
    dtag::String,
)
    futures = [
        @spawnat :any pfilter(eco, trial, t, domains, prunecfg) 
        for trial in trials
    ]
    allecostats = [fetch(future) for future in futures]
    d = Dict{String, Vector{Float64}}()
    fill_statdict!(d, "geno-complexity", StatFeatures.(
        zip([ecostats.stats.genostats.complexity for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "geno-novelty", StatFeatures.(
        zip([ecostats.stats.genostats.novelty for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "geno-change", StatFeatures.(
        zip([ecostats.stats.genostats.change for ecostats in allecostats]...))
    )
    fill_statdict!(d, "geno-ecology", StatFeatures.(
        zip([ecostats.stats.genostats.ecology for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "min-fitness", StatFeatures.(
        zip([ecostats.stats.minfitness for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "min-eplen", StatFeatures.(
        zip([ecostats.stats.min_eplen for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "min-complexity", StatFeatures.(
        zip([ecostats.stats.minstats.complexity for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "min-novelty", StatFeatures.(
        zip([ecostats.stats.minstats.novelty for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "min-change", StatFeatures.(
        zip([ecostats.stats.minstats.change for ecostats in allecostats]...))
    )
    fill_statdict!(d, "min-ecology", StatFeatures.(
        zip([ecostats.stats.minstats.ecology for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "modes-complexity", StatFeatures.(
        zip([ecostats.stats.modestats.complexity for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "modes-eplen", StatFeatures.(
        zip([ecostats.stats.mode_eplen for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "modes-novelty", StatFeatures.(
        zip([ecostats.stats.modestats.novelty for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "modes-change", StatFeatures.(
        zip([ecostats.stats.modestats.change for ecostats in allecostats]...))
    )
    fill_statdict!(d, "modes-ecology", StatFeatures.(
        zip([ecostats.stats.modestats.ecology for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "modes-fitness", StatFeatures.(
        zip([ecostats.stats.modefitness for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "levdist", StatFeatures.(
        zip([ecostats.stats.levdist for ecostats in allecostats]...)
    ))

    spids = allecostats[1].spstats |> keys |> collect
    for spid in spids
        fill_statdict!(d, "$spid-geno-complexity", StatFeatures.(
            zip([ecostats.spstats[spid].genostats.complexity for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-geno-novelty", StatFeatures.(
            zip([ecostats.spstats[spid].genostats.novelty for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-geno-change", StatFeatures.(
            zip([ecostats.spstats[spid].genostats.change for ecostats in allecostats]...))
        )
        fill_statdict!(d, "$spid-geno-ecology", StatFeatures.(
            zip([ecostats.spstats[spid].genostats.ecology for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-fitness", StatFeatures.(
            zip([ecostats.spstats[spid].minfitness for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-complexity", StatFeatures.(
            zip([ecostats.spstats[spid].minstats.complexity for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-eplen", StatFeatures.(
            zip([ecostats.spstats[spid].min_eplen for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-novelty", StatFeatures.(
            zip([ecostats.spstats[spid].minstats.novelty for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-change", StatFeatures.(
            zip([ecostats.spstats[spid].minstats.change for ecostats in allecostats]...))
        )
        fill_statdict!(d, "$spid-min-ecology", StatFeatures.(
            zip([ecostats.spstats[spid].minstats.ecology for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-fitness", StatFeatures.(
            zip([ecostats.spstats[spid].modefitness for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-eplen", StatFeatures.(
            zip([ecostats.spstats[spid].mode_eplen for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-levdist", StatFeatures.(
            zip([ecostats.spstats[spid].levdist for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-complexity", StatFeatures.(
            zip([ecostats.spstats[spid].modestats.complexity for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-novelty", StatFeatures.(
            zip([ecostats.spstats[spid].modestats.novelty for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-change", StatFeatures.(
            zip([ecostats.spstats[spid].modestats.change for ecostats in allecostats]...))
        )
        fill_statdict!(d, "$spid-modes-ecology", StatFeatures.(
            zip([ecostats.spstats[spid].modestats.ecology for ecostats in allecostats]...)
        ))
    end
    d = DataFrame(d)
    serialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "modes-$dtag.jls"), d)
    d
end

function modes_ctrl(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(),
    dtag::String = "",
)
    domains = Dict(
        ("ctrl1", "ctrl2") => LingPredGame(Control())
    )
    domodes("ctrl", trials, t, domains, prunecfg, dtag)
end
function modes_coop(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), 
    dtag::String = "",
)
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MatchCoop())
    )
    domodes("coop", trials, t, domains, prunecfg, dtag)
end

function modes_comp(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), 
    dtag::String = "",
)
    domains = Dict(
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    domodes("comp", trials, t, domains, prunecfg, dtag)
end

function modes_matchmix(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), 
    dtag::String = "",
)
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MatchCoop()),
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    domodes("matchmix", trials, t, domains, prunecfg, dtag)
end

function modes_mismatchmix(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), dtag::String = "",
)
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MismatchCoop()),
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    domodes("mismatchmix", trials, t, domains, prunecfg, dtag)
end


function modes_4MatchMix(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), dtag::String = "",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MatchCoop()),
        ("B", "D") => LingPredGame(MatchCoop()),
    )
    domodes("4MatchMix", trials, t, domains, prunecfg, dtag)
end

function modes_4MatchMismatchMix(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), dtag::String = "",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MatchCoop()),
        ("B", "D") => LingPredGame(MismatchCoop()),
    )
    domodes("4MatchMix", trials, t, domains, prunecfg, dtag)
end

function modes_4MismatchMatchMix(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), dtag::String = "",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MismatchCoop()),
        ("B", "D") => LingPredGame(MatchCoop()),
    )
    domodes("4MatchMix", trials, t, domains, prunecfg, dtag)
end

function modes_4MismatchMix(;
    trials::UnitRange{Int} = 1:20, t::Int = 50, prunecfg::PruneCfg = AgePruneCfg(), dtag::String = "",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MismatchCoop()),
        ("B", "D") => LingPredGame(MismatchCoop()),
    )
    domodes("4MatchMix", trials, t, domains, prunecfg, dtag)
end