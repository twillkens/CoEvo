using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using Pidfile
@everywhere using CoEvo
@everywhere using JLD2
@everywhere include("fssf.jl")
using StatsBase
using DataFrames
@everywhere using StableRNGs
@everywhere using Random
@everywhere using DataStructures
using Serialization

@everywhere struct FilterIndiv{I <: FSMIndiv}
    indiv::I
    prevtag::Int
    currtag::Int
end

@everywhere struct FilterTag
    gen::Int
    spid::String
    iid::String
    prevtag::Int
    currtag::Int
end


@everywhere function pfilter(
    jld2file::JLD2.JLDFile, spid::String, t::Int, until::Int = typemax(Int)
)
    tagdict = Dict{String, Int}()
    childrengroup = jld2file["arxiv/1/species/$spid/children"]
    ftags = Vector{FilterTag}()
    for (tag, iid) in enumerate(keys(childrengroup))
        tagdict[iid] = tag
        prevtag = -1
        ftag = FilterTag(1, spid, iid, prevtag, tag)
        push!(ftags, ftag)
    end
    pfiltered = [ftags]

    for gen in 2:length(keys(jld2file["arxiv"]))
        if gen > until
            break
        end
        if gen % 1000 == 0
            println("$(myid() - 1)-$spid-$gen")
        end
        childrengroup = jld2file["arxiv/$gen/species/$spid/children"]
        new_tagdict = Dict{String, Int}()
        if gen % t == 0
            ftags = Vector{FilterTag}()
            for (tag, iid) in enumerate(keys(childrengroup))
                new_tagdict[iid] = tag
                pid = first(childrengroup[iid]["pids"])
                prevtag = tagdict[string(pid)]
                ftag = FilterTag(gen, spid, iid, prevtag, tag)
                push!(ftags, ftag)
            end
            nexttags = Set([ftag.prevtag for ftag in ftags])
            filter!(ftag -> ftag.currtag in nexttags, pfiltered[end])
            push!(pfiltered, ftags)
        else
            for iid in keys(childrengroup)
                pid = first(childrengroup[iid]["pids"])
                new_tagdict[iid] = tagdict[string(pid)]
            end
        end
        tagdict = new_tagdict
    end
    pop!(pfiltered)
    close(jld2file)
    GC.gc()
    pfiltered
end

@everywhere function pfilter(
    eco::String, trial::Int, spid::String, t::Int, until::Int = typemax(Int)
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    pfilter(jld2file, spid, t, until)
end


@everywhere function pfilter(eco::String, trial::Int, t::Int, until::Int = typemax(Int))
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    spids = keys(jld2file["arxiv/1/species"])
    close(jld2file)
    println("spids: $spids")
    spfiltered = Dict(spid => pfilter(eco, trial, spid, t, until) for spid in spids)
    close(jld2file)
    spfiltered
end

function pfilter(eco::String, trials::UnitRange{Int}, t::Int, until::Int = typemax(Int))
    futures = [
        @spawnat :any pfilter(eco, trial, t, until) 
        for trial in trials
    ]
    [fetch(future) for future in futures]
end

function writepfilter(eco::String, trial::Int, t::Int, until::Int = typemax(Int))
    spfiltered = pfilter(eco, trial, t, until)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "pfilter-trial-$t.jld2")
    jld2file = jldopen(jld2path, "w")
    for (spid, spfilter) in spfiltered
        jld2file[spid] = spfilter
    end
    close(jld2file)
end

function writepfilter(eco::String, trials::UnitRange{Int}, t::Int, until::Int = typemax(Int))
    allspfiltered = pfilter(eco, trials, t, until)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "pfilter-tags.jld2")
    jld2file = jldopen(jld2path, "w")
    for i in eachindex(allspfiltered)
        jld2file["$i"] = allspfiltered[i]
    end
    close(jld2file)
end


function getindivs(jld2file::JLD2.JLDFile, allspftags::Dict{String, Vector{Vector{FilterTag}}})
    archiver = FSMIndivArchiver()
    allspindivs = Dict{String, Vector{Vector{FilterIndiv}}}()
    for (spid, allftags) in allspftags
        allspindivs[spid] = Vector{Vector{FilterIndiv}}()
        for ftags in allftags
            indivs = Vector{FilterIndiv}()
            for ftag in ftags
                igroup = jld2file["arxiv/$(ftag.gen)/species/$(ftag.spid)/children/$(ftag.iid)"]
                indiv = archiver(ftag.spid, ftag.iid, igroup)
                push!(indivs, FilterIndiv(indiv, ftag.prevtag, ftag.currtag))
            end
            push!(allspindivs[spid], indivs)
        end
    end
    close(jld2file)
    allspindivs
end

function getindivs(eco::String, trial::String, allspftags::Dict{String, Vector{Vector{FilterTag}}})
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "r")
    getindivs(jld2file, allspftags)
end

function getindivs(eco::String, trial::String)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    tags_jld2path = joinpath(ecopath, "pfilter-tags.jld2")
    tags_jld2file = jldopen(tags_jld2path, "r")
    allspftags = tags_jld2file["$trial"]
    getindivs(eco, trial, allspftags)
end

function writeindivs(eco::String)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    tags_jld2file = jldopen(joinpath(ecopath, "pfilter-tags.jld2"), "r")
    indivs_jld2path = joinpath(ecopath, "pfilter-indivs.jld2")
    jld = jldopen(indivs_jld2path, "w")
    close(jld)

    for trial in keys(tags_jld2file)
        println(trial)
        allspftags = tags_jld2file[trial]
        allspindivs = getindivs(eco, trial, allspftags)
        indiv_jld2file = jldopen(indivs_jld2path, "a")
        for (spid, spindivs) in allspindivs
            indiv_jld2file["$spid/$trial"] = spindivs
        end
        close(indiv_jld2file)
    end
end

function writecounts(eco::String)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    indivs_jld2file = jldopen(joinpath(ecopath, "pfilter-indivs.jld2"), "r")
    counts_jld2file = jldopen(joinpath(ecopath, "pfilter-counts.jld2"), "w")
    spids = keys(indivs_jld2file)
    for spid in spids
        println(spid)
        trials = keys(indivs_jld2file[spid])
        for trial in trials
            println(trial)
            allspindivs = indivs_jld2file["$spid/$trial"]
            for (fgen, findivs) in enumerate(allspindivs)
                counts_jld2file["$fgen/$spid/$trial"] = [findiv.indiv for findiv in findivs]
            end
        end
    end
    close(indivs_jld2file)
    dfdict = Dict{String, Vector{Float64}}()
    for fgen in keys(counts_jld2file)
        println(fgen)
        for spid in keys(counts_jld2file[fgen])
            if "$spid-geno-med" ∉ keys(dfdict)
                dfdict["$spid-geno-med"] = Vector{Float64}()
                dfdict["$spid-geno-upper"] = Vector{Float64}()
                dfdict["$spid-geno-lower"] = Vector{Float64}()
                dfdict["$spid-min-med"] = Vector{Float64}()
                dfdict["$spid-min-upper"] = Vector{Float64}()
                dfdict["$spid-min-lower"] = Vector{Float64}()
            end
            allindivs = FSMIndiv[]
            for trial in keys(counts_jld2file[fgen][spid])
                append!(allindivs, counts_jld2file["$fgen/$spid/$trial"])
            end
            allgenocounts = [
                length(indiv.geno.ones) + length(indiv.geno.zeros) for indiv in allindivs
            ]
            allmingenocounts = [
                length(indiv.mingeno.ones) + length(indiv.mingeno.zeros) for indiv in allindivs
            ]
            genosf = StatFeatures(allgenocounts)
            mingenosf = StatFeatures(allmingenocounts)
            counts_jld2file["$fgen/$spid/genosf"] = genosf
            counts_jld2file["$fgen/$spid/mingenosf"] = mingenosf
            push!(dfdict["$spid-geno-med"], genosf.median)
            push!(dfdict["$spid-geno-upper"], genosf.upper_quartile)
            push!(dfdict["$spid-geno-lower"], genosf.lower_quartile)
            push!(dfdict["$spid-min-med"], mingenosf.median)
            push!(dfdict["$spid-min-upper"], mingenosf.upper_quartile)
            push!(dfdict["$spid-min-lower"], mingenosf.lower_quartile)
        end
    end
    df = DataFrame(dfdict)
    counts_jld2file["df"] = df
    serialize(joinpath(ecopath, "$eco-counts.jls"), df)

    close(counts_jld2file)
end

function modesfilter(eco::String, trials::UnitRange{Int}, t::Int, until::Int = typemax(Int))
    writepfilter(eco, trials, t, until)
    writeindivs(eco)
    writecounts(eco)
end

function changenov(eco::String, spid::Symbol, trial::Int)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    indivs_jld2path = joinpath(ecopath, "pfilter-indivs.jld2")
    indivs_jld2file = jldopen(indivs_jld2path, "r")
    allspindivs = indivs_jld2file["$spid/$trial"]
    change = Vector{Int}()
    novelty = Vector{Int}()
    allgenos = Set([f.indiv.mingeno for f in allspindivs[1]])
    allgenovec = [f.indiv.mingeno for f in allspindivs[1]]
    for i in 2:(length(allspindivs))
        prevgenos = Set([f.indiv.mingeno for f in allspindivs[i - 1]])
        currgenos = Set([f.indiv.mingeno for f in allspindivs[i]])
        push!(change, length([geno for geno in currgenos if geno ∉ prevgenos]))
        append!(allgenovec, [f.indiv.mingeno for f in allspindivs[i]])
        nov = 0
        for geno in currgenos
            if geno ∉ allgenos
                nov += 1
                push!(allgenos, geno)
            end
        end
        push!(novelty, nov)
    end
    close(indivs_jld2file)
    change, novelty, allgenos, allgenovec
end

@everywhere function get_allgenphenos(eco::String, spid::String, trial::Int, gen::Int)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    trialpath = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(trialpath, "r")
    archiver = FSMIndivArchiver()
    genindivs = [
        archiver(string(spid), i, jld2file["arxiv/$gen/species/$spid/children/$i"]) 
        for i in keys(jld2file["arxiv/$gen/species/$spid/children"])
    ]
    close(jld2file)
    pcfg = FSMPhenoCfg()
    [pcfg(indiv) for indiv in genindivs]
end

@everywhere mutable struct KOPheno{I <: FSMIndiv}
    indiv::I
    prime::FSMPheno{UInt32}
    score::Float64
    kos::Dict{UInt32, FSMPheno{UInt32}}
    koscores::Dict{UInt32, Float64}
end

@everywhere function KOPheno(indiv::FSMIndiv, rng::AbstractRNG = StableRNG(42)) 
    pcfg = FSMPhenoCfg()
    onekos = [
        i => pcfg(indiv.ikey, rmstate(rng, indiv.mingeno, i)) 
        for i in indiv.mingeno.ones if i != indiv.mingeno.start
    ]
    zerokos = [
        i => pcfg(indiv.ikey, rmstate(rng, indiv.mingeno, i))
        for i in indiv.mingeno.zeros if i != indiv.mingeno.start
    ]
    kos = Dict{UInt32, FSMPheno{UInt32}}()
    [push!(kos, ko) for ko in onekos]
    [push!(kos, ko) for ko in zerokos]
    koscores = Dict(i => 0.0 for i in keys(kos))
    KOPheno(indiv, pcfg(indiv), 0.0, kos, koscores)
end

@everywhere function KOPheno(findiv::FilterIndiv)
    KOPheno(findiv.indiv)
end

@everywhere function fight!(kop1::KOPheno, kop2::KOPheno, domain::Domain)
    o_prime = stir(:ko, domain, NullObsConfig(), kop1.prime, kop2.prime)
    kop1.score += getscore(kop1.prime.ikey, o_prime)
    kop2.score += getscore(kop2.prime.ikey, o_prime)
    ko_outcomes1 = Dict(
        s => stir(:ko, domain, NullObsConfig(), ko, kop2.prime) 
        for (s, ko) in kop1.kos
    )
    ko_outcomes2 = Dict(
        s => stir(:ko, domain, NullObsConfig(), kop1.prime, ko) 
        for (s, ko) in kop2.kos
    )

    ko_scores1 = Dict(s => getscore(kop1.prime.ikey, outcome) for (s, outcome) in ko_outcomes1)
    ko_scores2 = Dict(s => getscore(kop2.prime.ikey, outcome) for (s, outcome) in ko_outcomes2)
    for (s, score) in ko_scores1
        kop1.koscores[s] += score
    end
    for (s, score) in ko_scores2
        kop2.koscores[s] += score
    end
end

@everywhere function fight!(kop::KOPheno, p::FSMPheno{UInt32}, domain::Domain)
    o_prime = stir(:ko, domain, NullObsConfig(), kop.prime, p)
    kop.score += getscore(kop.prime.ikey, o_prime)
    ko_outcomes = Dict(
        s => stir(:ko, domain, NullObsConfig(), ko, p) 
        for (s, ko) in kop.kos
    )
    ko_scores = Dict(s => getscore(kop.prime.ikey, outcome) for (s, outcome) in ko_outcomes)
    for (s, score) in ko_scores
        kop.koscores[s] += score
    end
end

@everywhere function genocomplexity(eco::String, trial::Int, domains::Dict{Tuple{String, String}, <:Domain})
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    indivs_jld2path = joinpath(ecopath, "pfilter-indivs.jld2")
    indivs_jld2file = jldopen(indivs_jld2path, "r")

    spkeys = keys(indivs_jld2file)
    spdict = Dict(
        spid => [
            [KOPheno(indiv) for indiv in genvec]
            for genvec in indivs_jld2file["$spid/$trial"] 
        ]
        for spid in spkeys
    )
    close(indivs_jld2file)
    for ((spid1, spid2), domain) in domains
        genvec1 = spdict[spid1]
        genvec2 = spdict[spid2]
        for (i, (kophenos1, kophenos2)) in enumerate(zip(genvec1, genvec2))
            gen = i == 1 ? 1 : (i - 1) * 50
            println("fighting $spid1 vs $spid2 at gen $gen")
            phenos1 = get_allgenphenos(eco, spid1, trial, gen)
            phenos2 = get_allgenphenos(eco, spid2, trial, gen)
            for kop in kophenos1
                for p in phenos2
                    fight!(kop, p, domain)
                end
            end
            for kop in kophenos2
                for p in phenos1
                    fight!(kop, p, domain)
                end
            end
        end
    end
    spdict
end

function genocomplexity(
    eco::String, trange::UnitRange{Int}, domains::Dict{Tuple{String, String}, <:Domain}
)
    futures = [
        @spawn genocomplexity(eco, trial, domains) 
        for trial in trange
    ]
    tdicts = [fetch(f) for f in futures]
    complexity_jld2file = jldopen(
        joinpath(ENV["COEVO_DATA_DIR"], eco, "genocomplexity.jld2"), "w"
    )
    for (trial, tdict) in enumerate(tdicts)
        for (spid, kophenos) in tdict
            complexity_jld2file["$spid/$trial"] = kophenos
        end
    end
    close(complexity_jld2file)
end