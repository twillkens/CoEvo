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
@everywhere using HypothesisTests
@everywhere include("abstract.jl")
@everywhere include("util.jl")
@everywhere include("modesprune.jl")
@everywhere include("mstats.jl")
@everywhere include("ptags.jl")
@everywhere include("pfilter.jl")


# get meaningful sites for each persistent individual
function addstats!(
    df::DataFrame,
    domains::Dict{Tuple{String, String}, <:Domain}; 
    plevels::Vector{String} = ["full", "hopcroft", "visit", "age"], 
    metrics::Vector{String} = ["complexity", "novelty", "change", 
                               "ecology", "eplen", "levdist", "fitness", "coverage"]
)
    species = Set(["eco"])
    for (spid1, spid2) in keys(domains)
        push!(species, spid1)
        push!(species, spid2)
    end

    for species in species
        for plevel in plevels
            for metric in metrics
                entries = select(df, Regex("$(species)-$(plevel)-$(metric)"))
                means = Vector{Float64}()
                lowconfs = Vector{Float64}()
                hiconfs = Vector{Float64}()
                for row in eachrow(entries)
                    row = collect(row)
                    m = mean(row)
                    test = OneSampleTTest(row, m)
                    lowconf, hiconf = confint(test)
                    push!(means, m)
                    push!(lowconfs, lowconf)
                    push!(hiconfs, hiconf)
                end
                df[!, "$(species)-$(plevel)-$(metric)-mean"] = means
                df[!, "$(species)-$(plevel)-$(metric)-lowconf"] = lowconfs
                df[!, "$(species)-$(plevel)-$(metric)-hiconf"] = hiconfs
            end

        end
    end
end


function domodes(
    eco::String, 
    trials::UnitRange{Int},
    t::Int,
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
    dtag::String,
    parallel::Bool = true,
)
    if parallel
        futures = [
            @spawnat :any pfilter(eco, trial, t, domains, prunecfg) 
            for trial in trials
        ]
        alltrialstats = [fetch(future) for future in futures]
    else
        alltrialstats = [
            pfilter(eco, trial, t, domains, prunecfg) 
            for trial in trials
        ]
    end
    statdict = Dict{String, Vector{Float64}}()
    for trialstats in alltrialstats
        merge!(statdict, trialstats)
    end
    df = DataFrame(statdict)
    addstats!(df, domains)
    serialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "modes-$dtag.jls"), df)
    df
end


function modes_ctrl(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(),
    dtag::String = "modes-40",
)
    domains = Dict(
        ("ctrl1", "ctrl2") => LingPredGame(Control())
    )
    domodes("ctrl", trials, t, domains, prunecfg, dtag)
end

function modes_3ctrl(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(),
    dtag::String = "modes-40",
)
    domains = Dict(
        ("ctrl1", "ctrl2") => LingPredGame(Control()),
        ("ctrl2", "ctrl3") => LingPredGame(Control()),
    )
    domodes("3ctrl", trials, t, domains, prunecfg, dtag)
end

function modes_coop(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MatchCoop())
    )
    domodes("coop", trials, t, domains, prunecfg, dtag)
end

function modes_comp(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    domodes("comp", trials, t, domains, prunecfg, dtag)
end

function modes_3comp(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MatchComp())
    )
    domodes("3comp", trials, t, domains, prunecfg, dtag)
end

function modes_matchmix(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MatchCoop()),
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    domodes("matchmix", trials, t, domains, prunecfg, dtag)
end

function modes_mismatchmix(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MismatchCoop()),
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    domodes("mismatchmix", trials, t, domains, prunecfg, dtag)
end


function modes_4MatchMix(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MatchCoop()),
        ("B", "D") => LingPredGame(MatchCoop()),
    )
    domodes("4MatchMix", trials, t, domains, prunecfg, dtag)
end

function modes_4MatchMismatchMix(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MatchCoop()),
        ("B", "D") => LingPredGame(MismatchCoop()),
    )
    domodes("4MatchMismatchMix", trials, t, domains, prunecfg, dtag)
end

function modes_4MismatchMatchMix(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MismatchCoop()),
        ("B", "D") => LingPredGame(MatchCoop()),
    )
    domodes("4MismatchMatchMix", trials, t, domains, prunecfg, dtag)
end

function modes_4MismatchMix(;
    trials::UnitRange{Int} = 1:40, t::Int = 50, prunecfg::PruneCfg = ModesPruneRecordCfg(), 
    dtag::String = "modes-40",
)
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MismatchCoop()),
        ("B", "D") => LingPredGame(MismatchCoop()),
    )
    domodes("4MismatchMix", trials, t, domains, prunecfg, dtag)
end
