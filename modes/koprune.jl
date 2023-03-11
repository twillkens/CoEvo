export KOPrune, KOPruneCfg, fight!

struct KOPruneCfg <: PruneCfg end

mutable struct KOPrune{I <: FSMIndiv, O <: Outcome}
    ftag::FilterTag
    indiv::I
    prime::FSMPheno{UInt32}
    score::Float64
    eplen::Int
    kos::Dict{UInt32, FSMPheno{UInt32}}
    koscores::Dict{UInt32, Float64}
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
    kos = Dict{UInt32, FSMPheno{UInt32}}([onekos; zerokos])
    koscores = Dict(i => 0.0 for i in keys(kos))
    KOPrune(ftag, indiv, pcfg(indiv), 0.0, 0, kos, koscores)
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
function fight!(kop::KOPrune, p::FSMPheno, kofirst::Bool, domain::Domain)
    o_prime = kofirst ? 
        stir(:ko, domain, LingPredObsConfig(), kop.prime, p) : 
        stir(:ko, domain, LingPredObsConfig(), p, kop.prime)
    kop.score += getscore(kop.prime.ikey, o_prime)
    try 
        kop.eplen += length(first(values(o_prime.obs.states)))
    catch
        kop.eplen += 0
    end
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
function fight!(
    myspid::String, 
    koprunes::Vector{<:KOPrune},
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain}
)
    for koprune in koprunes
        for ((spid1, spid2), domain) in domains
            if spid1 == myspid
                for pheno in genphenodict[spid2]
                    fight!(koprune, pheno, true, domain)
                end
            elseif spid2 == myspid
                for pheno in genphenodict[spid1]
                    fight!(koprune, pheno, false, domain)
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
        p.ftag, p.indiv, modepheno, 0.0, 0, 
        Dict{UInt32, FSMPheno{UInt32}}(), Dict{UInt32, Float64}()
    )
    fight!(p.ftag.spid, [modeko], genphenodict, domains)
    FilterIndiv(
        p.ftag, 
        p.indiv.geno, #nothing 
        p.indiv.mingeno, 
        minimize(p.currgeno), 
        p.score / length(genphenodict),
        modeko.score / length(genphenodict),
        p.eplen / length(genphenodict),
    )
end
