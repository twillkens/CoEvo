export KOPrune, KOPruneCfg, fight!

struct KOPruneCfg <: PruneCfg end

mutable struct KOPrune{I <: FSMIndiv}
    ftag::FilterTag
    indiv::I
    prime::FSMMinPheno{UInt32}
    kos::Dict{UInt32, FSMMinPheno{UInt32}}
    koscores::Dict{UInt32, Float64}
    score::Float64
    eplen::Float64
    prunescore::Float64
    prunelen::Float64
    outs::Vector{Vector{Bool}}
end

function KOPrune(ftag::FilterTag, indiv::FSMIndiv, rng::AbstractRNG = StableRNG(42)) 
    pcfg = FSMPhenoCfg()
    onekos = [
        i => pcfg(indiv.ikey, rmstate(rng, indiv.mingeno, i)) 
        for i in indiv.mingeno.ones if i != indiv.mingeno.start
    ]
    zerokos = [
        i => pcfg(indiv.ikey, rmstate(rng, indiv.mingeno, i))
        for i in indiv.mingeno.zeros if i != indiv.mingeno.start
    ]
    kos = Dict{UInt32, FSMMinPheno{UInt32}}([onekos; zerokos])
    koscores = Dict(i => 0.0 for i in keys(kos))
    KOPrune(
        ftag, 
        indiv, 
        pcfg(indiv), 
        kos, 
        koscores, 
        0.0, 
        0.0, 
        0.0, 
        0.0, 
        Vector{Vector{Bool}}()
    )
end


# get phenotypes of all persistent individuals at a given generation using the tags
function(cfg::KOPruneCfg)(jld2file::JLD2.JLDFile, ftags::Vector{FilterTag})
    archiver = FSMIndivArchiver()
    [
        KOPrune(
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

# fight a KO phenotype against a phenotype according to the domain
function fight!(
    kop::KOPrune, p::FSMPheno, kofirst::Bool, domain::Domain, get_koscores::Bool = true
)
    o_prime = kofirst ? 
        stir(:ko, domain, LingPredObsConfig(), kop.prime, p) : 
        stir(:ko, domain, LingPredObsConfig(), p, kop.prime)
    kop.score += getscore(kop.prime.ikey, o_prime)
    kop.eplen += length(first(values(o_prime.obs.states)))
    outs = o_prime.obs.outs[kop.prime.ikey]
    push!(kop.outs, outs)
    if get_koscores
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
end

# fight all phenotypes of other species against each KO phenotype according to the domain
function fight!(
    myspid::String, 
    koprunes::Vector{<:KOPrune},
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain},
    get_koscores::Bool = true
)
    for koprune in koprunes
        for ((spid1, spid2), domain) in domains
            if spid1 == myspid
                for pheno in genphenodict[spid2]
                    fight!(koprune, pheno, true, domain, get_koscores)
                end
            elseif spid2 == myspid
                for pheno in genphenodict[spid1]
                    fight!(koprune, pheno, false, domain, get_koscores)
                end
            end
        end
    end
end

function FilterIndiv(
    p::KOPrune, 
    genphenodict::Dict{String, <:Vector{<:FSMPheno}},
    domains::Dict{Tuple{String, String}, <:Domain}
)
    modegeno = p.indiv.mingeno
    for (s, score) in p.koscores
        if score >= p.score
            modegeno = rmstate(StableRNG(42), modegeno, s)
        end
    end
    modepheno = FSMPhenoCfg()(p.indiv.ikey, modegeno)
    modeko = KOPrune(
        p.ftag, p.indiv, modepheno,
        Dict{UInt32, FSMMinPheno{UInt32}}(), 
        Dict{UInt32, Float64}(),
        0.0, 0.0, 0.0, 0.0, Vector{Vector{Bool}}()
    )
    fight!(modeko.ftag.spid, [modeko], genphenodict, domains, false)
    lev = Levenshtein()
    levdist = sum(lev(modeko.outs[i], p.outs[i]) for i in 1:length(modeko.outs))

    n_others = sum(length(v) for v in values(genphenodict))
    # println(
    #     "---\n",
    #     "pscore: $(p.score), peplen: $(p.eplen)\n",
    #     "modepscore: $(modeko.score), modepeplen: $(modeko.eplen)\n",
    #     "$(p.score / n_others), $(p.eplen / n_others)\n",
    #     "$(modeko.score / n_others), $(modeko.eplen / n_others)\n",
    #     "len outs: $(length(p.outs)), $(length(modeko.outs)))\n"
    # )

    FilterIndiv(
        p.ftag, 
        p.indiv.geno, #nothing 
        p.indiv.mingeno, 
        minimize(modegeno), 
        p.score / n_others,
        modeko.score / n_others,
        p.eplen / n_others,
        modeko.eplen / n_others,
        levdist / n_others,
    )
end
