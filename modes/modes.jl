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
using Serialization

@everywhere struct FilterTag
    gen::Int
    spid::String
    iid::String
    prevtag::Int
    currtag::Int
end

@everywhere mutable struct KOPheno{I <: FSMIndiv, O <: Outcome}
    ftag::FilterTag
    indiv::I
    prime::FSMPheno{UInt32}
    score::Float64
    eplen::Int
    kos::Dict{UInt32, FSMPheno{UInt32}}
    koscores::Dict{UInt32, Float64}
    outcomes::Dict{IndivKey, O}
end

@everywhere function KOPheno(ftag::FilterTag, indiv::FSMIndiv, rng::AbstractRNG = StableRNG(42)) 
    pcfg = FSMPhenoCfg()
    onekos = [
        i => pcfg(indiv.ikey, rmstate(rng, indiv.mingeno, i)) 
        for i in indiv.mingeno.ones if i != indiv.mingeno.start
    ]
    zerokos = [
        i => pcfg(indiv.ikey, rmstate(rng, indiv.mingeno, i))
        for i in indiv.mingeno.zeros if i != indiv.mingeno.start
    ]
    kos = Dict{UInt32, FSMPheno{UInt32}}([onekos; zerokos])
    koscores = Dict(i => 0.0 for i in keys(kos))
    KOPheno(ftag, indiv, pcfg(indiv), 0.0, 0, kos, koscores, Dict{IndivKey, Outcome}())
end

# get phenotypes of all persistent individuals at a given generation using the tags
@everywhere function get_kophenos(jld2file::JLD2.JLDFile, ftags::Vector{FilterTag})
    archiver = FSMIndivArchiver()
    [
        KOPheno(
            ftag,
            archiver(
                ftag.spid, 
                ftag.iid, 
                jld2file["arxiv/$(ftag.gen)/species/$(ftag.spid)/children/$(ftag.iid)"]
            ),
        )
        for ftag in ftags
    ]
end

# get phenotypes of all other species at a given generation, excluding my species
@everywhere function get_genphenodict(jld2file::JLD2.JLDFile, gen::Int, myspid::String) 
    pcfg = FSMPhenoCfg()
    archiver = FSMIndivArchiver()
    Dict(
        spid => [
            pcfg(
                archiver(
                    spid, 
                    iid, 
                    jld2file["arxiv/$gen/species/$spid/children/$iid"]
                )
            )
            for iid in keys(jld2file["arxiv/$gen/species/$spid/children"])
        ]
        for spid in keys(jld2file["arxiv/$gen/species"]) if spid != myspid
    )
end

# fight a KO phenotype against a phenotype according to the domain
@everywhere function fight!(kop::KOPheno, p::FSMPheno, kofirst::Bool, domain::Domain)
    o_prime = kofirst ? 
        stir(:ko, domain, LingPredObsConfig(), kop.prime, p) : 
        stir(:ko, domain, LingPredObsConfig(), p, kop.prime)

    kop.score += getscore(kop.prime.ikey, o_prime)
    try 
        kop.eplen += length(first(values(o_prime.obs.states)))
    catch
        kop.eplen += 0
    end
    kop.outcomes[p.ikey] = o_prime
    ko_outcomes = Dict(
        s => kofirst ? 
            stir(:ko, domain, NullObsConfig(), ko, p) :
            stir(:ko, domain, NullObsConfig(), p, ko)
        for (s, ko) in kop.kos
    )
    ko_scores = Dict(s => getscore(kop.prime.ikey, outcome) for (s, outcome) in ko_outcomes)
    for (s, score) in ko_scores
        kop.koscores[s] += score
    end
end

# fight all phenotypes of other species against each KO phenotype according to the domain
@everywhere function fight!(
    myspid::String, 
    kophenos::Vector{<:KOPheno},
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain}
)
    for kopheno in kophenos
        for ((spid1, spid2), domain) in domains
            if spid1 == myspid
                for pheno in genphenodict[spid2]
                    fight!(kopheno, pheno, true, domain)
                end
            elseif spid2 == myspid
                for pheno in genphenodict[spid1]
                    fight!(kopheno, pheno, false, domain)
                end
            end
        end
    end
end

@everywhere mutable struct FilterIndiv{G1 <: FSMGeno, G2 <: FSMGeno, G3 <: FSMGeno}
    ftag::FilterTag
    geno::G1
    mingeno::G2
    modegeno::G3
    fitness::Float64
    eplen::Float64
end

@everywhere function FilterIndiv(p::KOPheno)
    modegeno = p.indiv.mingeno
    for (s, score) in p.koscores
        if score >= p.score
            modegeno = rmstate(StableRNG(42), modegeno, s)
        end
    end
    FilterIndiv(
        p.ftag, 
        p.indiv.geno, p.indiv.mingeno, minimize(modegeno), 
        p.score / 50, p.eplen / 50
    )
end

@everywhere function getchanges(allfsets::Vector{<:Set{<:FSMGeno}})
    changes = [length(allfsets[1])]
    for i in 2:(length(allfsets))
        prevgenos = allfsets[i - 1]
        currgenos = allfsets[i]
        change = length([geno for geno in currgenos if geno ∉ prevgenos])
        push!(changes, change)
    end
    changes
end

@everywhere function getnovelties(allfsets::Vector{<:Set{<:FSMGeno}})
    novelties = [length(allfsets[1])]
    allgenos = Set([geno for geno in allfsets[1]])
    for i in 2:(length(allfsets))
        currgenos = allfsets[i]
        novelty = length([geno for geno in currgenos if geno ∉ allgenos])
        push!(novelties, novelty)
        union!(allgenos, currgenos)
    end
    novelties
end

@everywhere function getcomplexities(allfsets::Vector{<:Set{<:FSMGeno}})
    complexities = Int[]
    for i in 1:(length(allfsets))
        currgenos = allfsets[i]
        complexity = maximum([length(geno.ones) + length(geno.zeros) for geno in currgenos])
        push!(complexities, complexity)
    end
    complexities
end

@everywhere function getecologies(
    allfvecs::Vector{<:Vector{<:FSMGeno}}, allfsets::Vector{<:Set{<:FSMGeno}}
)
    ecologies = Float64[]
    for (fvec, fset) in zip(allfvecs, allfsets)
        pcs = Float64[]
        for s in fset
            pc = 0
            for v in fvec
                if v == s
                    pc += 1
                end
            end
            push!(pcs, pc / length(fvec))
        end
        push!(ecologies, -sum(pc * log(2, pc) for pc in pcs))
    end
    ecologies
end


@everywhere function getfitnesses(allfindivs::Vector{<:Vector{<:FilterIndiv}})
    [mean([findiv.fitness for findiv in findivs]) for findivs in allfindivs]
end

@everywhere function geteplens(allfindivs::Vector{<:Vector{<:FilterIndiv}})
    [mean([findiv.eplen for findiv in findivs]) for findivs in allfindivs]
end

@everywhere struct ModesStats
    change::Vector{Int}
    novelty::Vector{Int}
    complexity::Vector{Float64}
    ecology::Vector{Float64}
end

@everywhere function ModesStats(allfvecs::Vector{<:Vector{<:FSMGeno}})
    allfsets = [Set(fgenos) for fgenos in allfvecs]
    change = getchanges(allfsets)
    novelty = getnovelties(allfsets)
    complexity = getcomplexities(allfsets)
    ecology = getecologies(allfvecs, allfsets)
    ModesStats(change, novelty, complexity, ecology)
end


@everywhere struct SpeciesStats
    spid::String
    genostats::ModesStats
    minstats::ModesStats
    modestats::ModesStats
    fitnesses::Vector{Float64}
    eplens::Vector{Float64}
end



@everywhere function SpeciesStats(spid::String, allfindivs::Vector{<:Vector{<:FilterIndiv}})
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
    fitnesses = getfitnesses(allfindivs)
    eplens = geteplens(allfindivs)
    SpeciesStats(spid, genostats, mingenostats, modestats, fitnesses, eplens)
end

@everywhere struct FilterResults{I <: FilterIndiv}
    spid::String
    t::Int
    allfindivs::Vector{Vector{I}}
    stats::SpeciesStats
end

# get meaningful sites for each persistent individual
@everywhere function pfilter(
    jld2file::JLD2.JLDFile,
    spid::String,
    pftags::Vector{Vector{FilterTag}},
    t::Int,
    domains::Dict{Tuple{String, String}, <:Domain}
)
    allfindivs = Vector{Vector{FilterIndiv}}()
    for (gen, ftags) in enumerate(pftags)
        gen = gen == 1 ? 1 : (gen - 1) * t
        println("filtering $spid at gen $gen")
        kophenos = get_kophenos(jld2file, ftags)
        genphenodict = get_genphenodict(jld2file, gen, spid)
        fight!(spid, kophenos, genphenodict, domains)
        push!(allfindivs, [FilterIndiv(kopheno) for kopheno in kophenos])
    end
    FilterResults(spid, t, allfindivs, SpeciesStats(spid, allfindivs))
end

# filter to get the tags of the persistent individuals
@everywhere function init_pftags(jld2file::JLD2.JLDFile, spid::String)
    tagdict = Dict{String, Int}()
    childrengroup = jld2file["arxiv/1/species/$spid/children"]
    ftags = Vector{FilterTag}()
    for (tag, iid) in enumerate(keys(childrengroup))
        tagdict[iid] = tag
        prevtag = -1
        ftag = FilterTag(1, spid, iid, prevtag, tag)
        push!(ftags, ftag)
    end
    pftags = [ftags]
    tagdict, pftags
end

@everywhere function tfilter!(
    jld2file::JLD2.JLDFile, 
    gen::Int,
    spid::String,
    pftags::Vector{Vector{FilterTag}},
    tagdict::Dict{String, Int}, 
)
    childrengroup = jld2file["arxiv/$gen/species/$spid/children"]
    new_tagdict = Dict{String, Int}()
    ftags = Vector{FilterTag}()
    for (tag, iid) in enumerate(keys(childrengroup))
        new_tagdict[iid] = tag
        pid = first(childrengroup[iid]["pids"])
        prevtag = tagdict[string(pid)]
        ftag = FilterTag(gen, spid, iid, prevtag, tag)
        push!(ftags, ftag)
    end
    nexttags = Set([ftag.prevtag for ftag in ftags])
    filter!(ftag -> ftag.currtag in nexttags, pftags[end])
    push!(pftags, ftags)
    new_tagdict
end

@everywhere function tpass!(
    jld2file::JLD2.JLDFile, 
    gen::Int,
    spid::String,
    tagdict::Dict{String, Int},
)
    childrengroup = jld2file["arxiv/$gen/species/$spid/children"]
    Dict(
        iid => tagdict[string(first(childrengroup[iid]["pids"]))] 
        for iid in keys(childrengroup)
    )
end

@everywhere function pfilter(
    jld2file::JLD2.JLDFile, 
    spid::String,
    t::Int, 
    domains::Dict{Tuple{String, String}, <:Domain},
    until::Int = typemax(Int)
)
    tagdict, pftags = init_pftags(jld2file, spid)
    for gen in 2:length(keys(jld2file["arxiv"]))
        if gen > until
            break
        end
        if gen % 1000 == 0
            println("$(myid() - 1)-$spid-$gen")
        end
        tagdict = gen % t == 0 ? 
            tfilter!(jld2file, gen, spid, pftags, tagdict) : 
            tpass!(jld2file, gen, spid, tagdict)
    end
    pop!(pftags)
    pfilter(jld2file, spid, pftags, t, domains)
end

@everywhere struct EcoStats
    eco::String
    trial::Int
    t::Int
    stats::SpeciesStats
    spstats::Dict{String, SpeciesStats}
end

@everywhere function EcoStats(
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

@everywhere function pfilter(
    eco::String, 
    trial::Int,
    t::Int, 
    domains::Dict{Tuple{String, String}, <:Domain},
    until::Int = typemax(Int)
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    spids = keys(jld2file["arxiv/1/species"])
    fdict = Dict(spid => pfilter(jld2file, spid, t, domains, until) for spid in spids)
    close(jld2file)
    EcoStats(eco, trial, t, fdict)
end


function fill_statdict!(
    d::Dict{String, Vector{Float64}}, metric::String, alls::Vector{StatFeatures}
)
    d["$metric-med"] =   [s.median for s in alls]
    d["$metric-std"] =   [s.std for s in alls]
    d["$metric-var"] =   [s.variance for s in alls]
    d["$metric-mean"] =  [s.mean for s in alls]
    d["$metric-upper"] = [s.upper_quartile for s in alls]
    d["$metric-lower"] = [s.lower_quartile for s in alls]
end

function pfilter(
    eco::String, 
    trials::UnitRange{Int},
    t::Int,
    domains::Dict{Tuple{String, String}, <:Domain},
    until::Int = 25_000
)
    futures = [
        @spawnat :any pfilter(eco, trial, t, domains, until) 
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
    fill_statdict!(d, "modes-novelty", StatFeatures.(
        zip([ecostats.stats.modestats.novelty for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "modes-change", StatFeatures.(
        zip([ecostats.stats.modestats.change for ecostats in allecostats]...))
    )
    fill_statdict!(d, "modes-ecology", StatFeatures.(
        zip([ecostats.stats.modestats.ecology for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "fitness", StatFeatures.(
        zip([ecostats.stats.fitnesses for ecostats in allecostats]...)
    ))
    fill_statdict!(d, "eplen", StatFeatures.(
        zip([ecostats.stats.eplens for ecostats in allecostats]...)
    ))

    spids = allecostats[1].spstats |> keys |> collect
    for spid in spids
        fill_statdict!(d, "$spid-geno-complexity", StatFeatures.(
            zip([ecostats.stats.genostats.complexity for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-geno-novelty", StatFeatures.(
            zip([ecostats.stats.genostats.novelty for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-geno-change", StatFeatures.(
            zip([ecostats.stats.genostats.change for ecostats in allecostats]...))
        )
        fill_statdict!(d, "$spid-geno-ecology", StatFeatures.(
            zip([ecostats.stats.genostats.ecology for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-complexity", StatFeatures.(
            zip([ecostats.stats.minstats.complexity for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-novelty", StatFeatures.(
            zip([ecostats.stats.minstats.novelty for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-min-change", StatFeatures.(
            zip([ecostats.stats.minstats.change for ecostats in allecostats]...))
        )
        fill_statdict!(d, "$spid-min-ecology", StatFeatures.(
            zip([ecostats.stats.minstats.ecology for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-complexity", StatFeatures.(
            zip([ecostats.stats.modestats.complexity for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-novelty", StatFeatures.(
            zip([ecostats.stats.modestats.novelty for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-modes-change", StatFeatures.(
            zip([ecostats.stats.modestats.change for ecostats in allecostats]...))
        )
        fill_statdict!(d, "$spid-modes-ecology", StatFeatures.(
            zip([ecostats.stats.modestats.ecology for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-fitness", StatFeatures.(
            zip([ecostats.stats.fitnesses for ecostats in allecostats]...)
        ))
        fill_statdict!(d, "$spid-eplen", StatFeatures.(
            zip([ecostats.stats.eplens for ecostats in allecostats]...)
        ))
    end
    d = DataFrame(d)
    serialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "modes.jls"), d)
    d
end

function pfilter_ctrl()
    domains = Dict(
        ("ctrl1", "ctrl2") => LingPredGame(Control())
    )
    pfilter("ctrl", 1:20, 50, domains)
end
function pfilter_coop()
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MatchCoop())
    )
    pfilter("coop", 1:20, 50, domains)
end

function pfilter_comp(
    t::Int = 50,
    until::Int = 25_000
)
    domains = Dict(
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    pfilter("comp", 1:20, t, domains, until)
end

function pfilter_matchmix()
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MatchCoop()),
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    pfilter("matchmix", 1:20, 50, domains)
end

function pfilter_mismatchmix()
    domains = Dict(
        ("host", "symbiote") => LingPredGame(MismatchCoop()),
        ("host", "parasite") => LingPredGame(MatchComp())
    )
    pfilter("mismatchmix", 1:20, 50, domains)
end

function pfilter_4MatchMix()
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MatchCoop()),
        ("B", "D") => LingPredGame(MatchCoop()),
    )
    pfilter("4MatchMix", 1:20, 50, domains)
end

function pfilter_4MatchMismatchMix()
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MatchCoop()),
        ("B", "D") => LingPredGame(MismatchCoop()),
    )
    pfilter("4MatchMismatchMix", 1:20, 50, domains)
end

function pfilter_4MismatchMatchMix()
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MismatchCoop()),
        ("B", "D") => LingPredGame(MatchCoop()),
    )
    pfilter("4MismatchMatchMix", 1:20, 50, domains)
end

function pfilter_4MismatchMix()
    domains = Dict(
        ("A", "B") => LingPredGame(MatchComp()),
        ("A", "C") => LingPredGame(MismatchCoop()),
        ("B", "D") => LingPredGame(MismatchCoop()),
    )
    pfilter("4MismatchMix", 1:20, 50, domains)
end
