export get_genphenodict, fill_statdict!


function fill_statdict!(
    d::Dict{String, Vector{Float64}}, metric::String, alls::Vector{StatFeatures}
)
    d["$metric-med"] =   [s.median for s in alls]
    d["$metric-std"] =   [s.std for s in alls]
    d["$metric-var"] =   [s.variance for s in alls]
    d["$metric-mean"] =  [s.mean for s in alls]
    d["$metric-upper-quart"] = [s.upper_quartile for s in alls]
    d["$metric-lower-quart"] = [s.lower_quartile for s in alls]
    d["$metric-upper-conf"] = [s.upper_confidence for s in alls]
    d["$metric-lower-conf"] = [s.lower_confidence for s in alls]
end

# get phenotypes of all other species at a given generation, excluding my species
function get_genphenodict(jld2file::JLD2.JLDFile, gen::Int, myspid::String) 

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
    #k = keys(jld2file["arxiv/$gen/species"])
    #gk = keys(d)
    #ok = [spid == myspid for spid in keys(jld2file["arxiv/$gen/species"])]
    #println("myspid: $myspid, jlkeys: $k, genkeys: $gk, ok: $ok")
    #d
end