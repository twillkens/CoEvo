export BFTPrune, traverse!, get_bftphenos

mutable struct BFTPrune{I <: FSMIndiv}
    ftag::FilterTag
    indiv::I
    score::Float64
    currgeno::FSMGeno{UInt32}
    currscore::Float64
    prunegeno::FSMGeno{UInt32}
    prunescore::Float64
    eplen::Float64
    prunelen::Float64
    levdist::Float64
end

function traverse!(
    bft::BFTPrune, 
    queue::Deque{UInt32},
    visited::Set{UInt32},
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain}
)
    state = pop!(queue)
    if state in visited
        return
    end
    push!(visited, state)
    prunepheno = FSMPhenoCfg()(bft.indiv.ikey, bft.currgeno)
    pushfirst!(queue, first(act(prunepheno, state, true)))
    pushfirst!(queue, first(act(prunepheno, state, false)))
    prunegeno = rmstate(StableRNG(42), bft.currgeno, state)
    prunepheno = FSMPhenoCfg()(bft.indiv.ikey, prunegeno)
    score = 0.0
    for ((spid1, spid2), domain) in domains
        opponents = spid1 == bft.ftag.spid ? genphenodict[spid2] : genphenodict[spid1]
        for pheno in opponents
            p1, p2 = spid1 == bft.ftag.spid ? (prunepheno, pheno) : (pheno, prunepheno)
            o = stir(:bft, domain, NullObsConfig(), p1, p2) 
            score += getscore(bft.indiv.ikey, o)
        end
    end
    if score >= bft.score
        bft.currgeno = prunegeno
    end
    traverse!(bft, queue, visited, genphenodict, domains)
end

function fight!(
    bft::BFTPrune,
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain}
)
    bftpheno = FSMPhenoCfg()(bft.indiv.ikey, bft.currgeno)
    for ((spid1, spid2), domain) in domains
        #println("fighting $spid1 vs $spid2, bfspid: $(bft.ftag.spid), ok: $(spid1 == bft.ftag.spid), keys: $(keys(genphenodict))")
        opponents = spid1 == bft.ftag.spid ? genphenodict[spid2] : genphenodict[spid1]
        for opp in opponents
            p1, p2 = spid1 == bft.ftag.spid ? (bftpheno, opp) : (opp, bftpheno)
            o = stir(:bft, domain, LingPredObsConfig(), p1, p2) 
            bft.score += getscore(bftpheno.ikey, o)
            bft.eplen += length(first(values(o.obs.states)))
        end
    end
    queue = Deque{UInt32}()
    pushfirst!(queue, first(act(bftpheno, first(bftpheno.start), true)))
    pushfirst!(queue, first(act(bftpheno, first(bftpheno.start), false)))
    visited = Set([first(bftpheno.start)])
    traverse!(bft, queue, visited, genphenodict, domains)

    bftpheno = FSMPhenoCfg()(bft.indiv.ikey, bft.currgeno)
    for ((spid1, spid2), domain) in domains
        #println("fighting $spid1 vs $spid2, bfspid: $(bft.ftag.spid), ok: $(spid1 == bft.ftag.spid), keys: $(keys(genphenodict))")
        opponents = spid1 == bft.ftag.spid ? genphenodict[spid2] : genphenodict[spid1]
        for opp in opponents
            p1, p2 = spid1 == bft.ftag.spid ? (bftpheno, opp) : (opp, bftpheno)
            o = stir(:bft, domain, LingPredObsConfig(), p1, p2) 
            bft.currscore += getscore(bftpheno.ikey, o)
        end
    end
end

function fight!(
    ::String, 
    bfts::Vector{<:BFTPrune}, 
    genphenodict::Dict{String, <:Vector{<:FSMPheno}},
    domains::Dict{Tuple{String, String}, <:Domain}
)
    for bft in bfts
        fight!(bft, genphenodict, domains)
    end
end

function BFTPrune(ftag::FilterTag, indiv::FSMIndiv,) 
    BFTPrune(ftag, indiv, 0.0, indiv.mingeno, 0.0, 0.0)
end

struct BFTPruneCfg <: PruneCfg end

function(cfg::BFTPruneCfg)(jld2file::JLD2.JLDFile, ftags::Vector{FilterTag})
    archiver = FSMIndivArchiver()
    [
        BFTPrune(
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

function FilterIndiv(
    p::BFTPrune, 
    others::Dict{String, <:Vector{<:FSMPheno}},
    ::Dict{Tuple{String, String}, <:Domain}
)
    n_others = sum([length(v) for v in values(others)])
    FilterIndiv(
        p.ftag, 
        p.indiv.geno, #nothing 
        p.indiv.mingeno, 
        minimize(p.currgeno), 
        p.score / n_others,
        p.currscore / n_others,
        p.eplen / n_others,
    )
end