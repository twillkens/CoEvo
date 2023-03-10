
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