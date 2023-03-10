using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using CoEvo
@everywhere using JLD2
using StatsBase
using DataFrames
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
    kop.eplen += length(first(values(o_prime.obs.states)))
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

@everywhere mutable struct FilterIndiv
    ftag::FilterTag
    geno::FSMGeno
    mingeno::FSMGeno
    modegeno::FSMGeno
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

@everywhere struct ModesStats
    change::Vector{Int}
    novelty::Vector{Int}
    complexity::Vector{Float64}
end

@everywhere function ModesStats(allfgenos::Vector{<:Vector{<:FSMGeno}})
    allfsets = [Set(fgenos) for fgenos in allfgenos]
    change = getchanges(allfsets)
    novelty = getnovelties(allfsets)
    complexity = getcomplexities(allfsets)
    #ecology = getecologies(allfsets)
    ModesStats(change, novelty, complexity) #, ecology)
end

@everywhere struct SpeciesStats{I <: FilterIndiv}
    spid::String
    # allfindivs::Vector{Vector{I}}
    genostats::ModesStats
    minstats::ModesStats
    modestats::ModesStats
    fitnesses::Vector{Float64}
    eplens::Vector{Float64}
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

@everywhere function getfitnesses(allfindivs::Vector{<:Vector{<:FilterIndiv}})
    [mean([findiv.fitness for findiv in findivs]) for findivs in allfindivs]
end

@everywhere function geteplens(allfindivs::Vector{<:Vector{<:FilterIndiv}})
    [mean([findiv.eplen for findiv in findivs]) for findivs in allfindivs]
end

@everywhere function SpeciesStats(spid::String, allfindivs::Vector{<:Vector{<:FilterIndiv}})
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
    SpeciesStats(spid, allfindivs, genostats, mingenostats, modestats, fitnesses, eplens)
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
        kophenos = get_kophenos(jld2file, ftags)
        genphenodict = get_genphenodict(jld2file, gen, spid)
        fight!(spid, kophenos, genphenodict, domains)
        push!(allfindivs, [FilterIndiv(kopheno) for kopheno in kophenos])
    end
    SpeciesStats(spid, allfindivs)
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
    spfiltered = Dict(spid => pfilter(jld2file, spid, t, domains, until) for spid in spids)
    close(jld2file)
    spfiltered
end

function pfilter(
    eco::String, 
    trials::UnitRange{Int},
    t::Int,
    domains::Dict{Tuple{String, String}, <:Domain},
    until::Int = typemax(Int)
)
    futures = [
        @spawnat :any pfilter(eco, trial, t, domains, until) 
        for trial in trials
    ]
    pfdict = [fetch(future) for future in futures]
end

function modesfilter(
    eco::String, 
    trials::UnitRange{Int},
    t::Int,
    domains::Dict{Tuple{String, String}, <:Domain},
    until::Int = typemax(Int)
)
    spfiltered = pfilter(eco, trials, t, domains, until)
    spmodes = Dict{String, Vector{Vector{FilterIndiv}}}()
    for (spid, allfindivs) in spfiltered
        spmodes[spid] = [findivs for findivs in allfindivs if !isempty(findivs)]
    end
    spmodes
end


