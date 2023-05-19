export AgePrune, AgePruneCfg

struct PruneGeno{G <: FSMGeno}
    geno::G
    fitness::Float64
    eplen::Float64
    levdist::Float64
    coverage::Float64
end

struct PruneBundle
    geno::FSMGeno{UInt32}
    score::Float64
    eplen::Float64
    n_others::Int
    visited::Set{UInt32}
    outputs::Dict{Tuple{LingPredRole, IndivKey}, Vector{Bool}}
end

function PruneBundle(
    ikey::IndivKey,
    geno::FSMGeno{UInt32},
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain},
)
    prunepheno = FSMPhenoCfg()(ikey, geno)
    visited = Set{UInt32}()
    eplen = 0.0
    score = 0.0
    n_others = 0
    outputs = Dict{Tuple{LingPredRole, IndivKey}, Vector{Bool}}()
    for ((spid1, spid2), domain) in domains
        others = spid1 == String(ikey.spid) ? genphenodict[spid2] : genphenodict[spid1]
        for pheno in others
            n_others += 1
            p1, p2 = spid1 == String(ikey.spid) ? (prunepheno, pheno) : (pheno, prunepheno)
            o = stir(:modes, domain, LingPredObsConfig(), p1, p2) 
            score += getscore(ikey, o)
            indiv_states = o.obs.states[ikey]
            eplen += length(indiv_states)
            union!(visited, Set(indiv_states))
            outputs[domain.variety, pheno.ikey] = o.obs.outs[ikey]
        end
    end
    PruneBundle(geno, score, eplen, n_others, visited, outputs)
end

function PruneGeno(
    bundle::PruneBundle, 
    base_outputs::Dict{Tuple{LingPredRole, IndivKey}, Vector{Bool}}
)
    lev = Levenshtein()
    levdist = 0.0
    for key in keys(base_outputs)
        levdist += lev(base_outputs[key], bundle.outputs[key])
    end

    PruneGeno(
        bundle.geno, 
        bundle.score / bundle.n_others,
        bundle.eplen / bundle.n_others,
        levdist / bundle.n_others,
        length(bundle.visited) / (length(bundle.geno.ones) + length(bundle.geno.zeros)),
    )
end

mutable struct ModesPruneRecord{G <: PruneGeno}
    ikey::IndivKey
    gen::Int
    prunegenos::Dict{String, G}
end

function ModesPruneRecord(
    ftag::FilterTag, 
    indiv::FSMIndiv, 
    genphenodict::Dict{String, <:Vector{<:FSMPheno}}, 
    domains::Dict{Tuple{String, String}, <:Domain}
)
    full = PruneBundle(indiv.ikey, indiv.geno, genphenodict, domains)
    hopcroft = PruneBundle(indiv.ikey, indiv.mingeno, genphenodict, domains)
    visitgeno = hopcroft.geno
    toremove = setdiff(union(visitgeno.ones, visitgeno.zeros), hopcroft.visited)
    for state in sort(collect(toremove), rev=true) 
        visitgeno = rmstate(StableRNG(42), visitgeno, state)
    end
    visit = PruneBundle(indiv.ikey, visitgeno, genphenodict, domains)
    agegeno = visit.geno
    tocheck = setdiff(union(agegeno.ones, agegeno.zeros), Set([agegeno.start]))
    for state in sort(collect(tocheck), rev=true) 
        checkgeno = rmstate(StableRNG(42), agegeno, state)
        checkbundle = PruneBundle(indiv.ikey, checkgeno, genphenodict, domains)
        if checkbundle.score >= visit.score
            agegeno = checkgeno
        end
    end
    age = PruneBundle(indiv.ikey, minimize(agegeno), genphenodict, domains)
    d = Dict(
        "full" => PruneGeno(full, hopcroft.outputs),
        "hopcroft" => PruneGeno(hopcroft, hopcroft.outputs),
        "visit" => PruneGeno(visit, hopcroft.outputs),
        "age" => PruneGeno(age, hopcroft.outputs),
    )
    if d["visit"].levdist > 0
        throw(ArgumentError("hopcroft levdist > 0"))
    end
    ModesPruneRecord(indiv.ikey, ftag.gen, d)
end

Base.@kwdef struct ModesPruneRecordCfg <: PruneCfg 
    rev::Bool = true
end

function(cfg::ModesPruneRecordCfg)(
    jld2file::JLD2.JLDFile, 
    ftags::Vector{FilterTag}, 
    genphenodict::Dict{String, <:Vector{<:FSMPheno}},
    domains::Dict{Tuple{String, String}, <:Domain}
)
    archiver = FSMIndivArchiver()
    [
        ModesPruneRecord(
            ftag,
            archiver(
                ftag.spid, 
                ftag.iid, 
                jld2file["arxiv/$(ftag.gen)/species/$(ftag.spid)/children/$(ftag.iid)"]
            ),
            genphenodict,
            domains,
        )
        for ftag in ftags
    ]
end