export AgePrune, AgePruneCfg

mutable struct AgePrune{I <: FSMIndiv}
    ftag::FilterTag
    indiv::I
    score::Float64
    prunegeno::FSMGeno{UInt32}
    prunescore::Float64
    eplen::Float64
    prunelen::Float64
    levdist::Float64
    rev::Bool
end

function AgePrune(ftag::FilterTag, indiv::FSMIndiv, rev::Bool = true)
    AgePrune(ftag, indiv, 0.0, indiv.mingeno, 0.0, 0.0, 0.0, 0.0, rev)
end

Base.@kwdef struct AgePruneCfg <: PruneCfg 
    rev::Bool = true
end

function(cfg::AgePruneCfg)(jld2file::JLD2.JLDFile, ftags::Vector{FilterTag})
    archiver = FSMIndivArchiver()
    [
        AgePrune(
            ftag,
            archiver(
                ftag.spid, 
                ftag.iid, 
                jld2file["arxiv/$(ftag.gen)/species/$(ftag.spid)/children/$(ftag.iid)"]
            ),
            cfg.rev
        )
        for ftag in ftags
    ]
end

function FilterIndiv(
    p::AgePrune, 
    others::Dict{String, <:Vector{<:FSMPheno}},
    ::Dict{Tuple{String, String}, <:Domain}
)
    n_others = sum([length(v) for v in values(others)])
    FilterIndiv(
        p.ftag, 
        p.indiv.geno, #nothing 
        p.indiv.mingeno, 
        minimize(p.prunegeno), 
        p.score / n_others,
        p.prunescore / n_others,
        p.eplen / n_others,
        p.prunelen / n_others,
        p.levdist / n_others,
    )
end

function fight!(
    aprune::AgePrune,
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain}
)
    apheno = FSMPhenoCfg()(aprune.indiv.ikey, aprune.prunegeno)
    for ((spid1, spid2), domain) in domains
        opponents = spid1 == aprune.ftag.spid ? genphenodict[spid2] : genphenodict[spid1]
        for pheno in opponents
            p1, p2 = spid1 == aprune.ftag.spid ? (apheno, pheno) : (pheno, apheno)
            o = stir(:age, domain, LingPredObsConfig(), p1, p2) 
            aprune.score += getscore(apheno.ikey, o)
            aprune.eplen += length(first(values(o.obs.states)))
        end
    end
    states = union(aprune.prunegeno.ones, aprune.prunegeno.zeros)
    delete!(states, aprune.prunegeno.start)
    for state in sort(collect(states), rev=aprune.rev)
        prunegeno = rmstate(StableRNG(42), aprune.prunegeno, state)
        prunepheno = FSMPhenoCfg()(aprune.indiv.ikey, prunegeno)
        score = 0.0
        for ((spid1, spid2), domain) in domains
            opponents = spid1 == aprune.ftag.spid ? genphenodict[spid2] : genphenodict[spid1]
            for pheno in opponents
                p1, p2 = spid1 == aprune.ftag.spid ? (prunepheno, pheno) : (pheno, prunepheno)
                o = stir(:age, domain, LingPredObsConfig(), p1, p2) 
                score += getscore(apheno.ikey, o)
            end
        end
        if score >= aprune.score
            aprune.prunegeno = prunegeno
        end
    end

    prunepheno = FSMPhenoCfg()(aprune.indiv.ikey, aprune.prunegeno)
    lev = Levenshtein()
    for ((spid1, spid2), domain) in domains
        opponents = spid1 == aprune.ftag.spid ? genphenodict[spid2] : genphenodict[spid1]
        for opp in opponents
            p1, p2 = spid1 == aprune.ftag.spid ? (apheno, opp) : (opp, apheno)
            o = stir(:bft, domain, LingPredObsConfig(), p1, p2) 
            aprune.prunescore += getscore(prunepheno.ikey, o)
            aprune.prunelen += length(first(values(o.obs.states)))
            aprune.levdist += lev(o.obs.states[prunepheno.ikey], o.obs.states[opp.ikey])
        end
    end
end

function fight!(
    ::String, 
    aprunes::Vector{<:AgePrune}, 
    genphenodict::Dict{String, <:Vector{<:FSMPheno}},
    domains::Dict{Tuple{String, String}, <:Domain}
)
    for ap in aprunes
        fight!(ap, genphenodict, domains)
    end
end
