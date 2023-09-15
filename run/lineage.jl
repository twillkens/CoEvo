function get_lineage(
    jld2file::JLD2.JLDFile,
    spid::String,
    iid::Int,
    gen::Int,
    pids::Vector{Int} = Int[],
)
    push!(pids, iid)
    while gen > 1
        pid = Int(first(jld2file["arxiv/$(gen)/species/$(spid)/children/$(iid)/pids"]))
        push!(pids, pid)
        iid = pid
        gen -= 1
    end
    pids
end


function get_lineage(
    eco::String, 
    trial::Int,
    spid::String,
    iid::Int,
    gen::Int,
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    lineage = get_lineage(jld2file, spid, iid, gen, Int[])
    close(jld2file)
    lineage
end


function filter_records!(lineage::Vector{Int64}, records::Vector{Vector{ModesPruneRecord}})
    lineage = Set(lineage)
    for gen_record in records
        filter!(record -> Int(record.ikey.iid) in lineage, gen_record)
    end
end


function pfilter_nostats(
    eco::String, 
    trial::Int,
    t::Int, 
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    spids = keys(jld2file["arxiv/1/species"])
    pftags = Dict(
        spid => deserialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "tags", "$spid-$trial.jls"))
        for spid in spids
    )
    fdict = Dict(
        spid => pfilter(
            jld2file, 
            spid, 
            pftags[spid], 
            t, 
            filter(d -> spid ∈ first(d), domains), 
            prunecfg
        ) 
        for spid in spids
    )
    close(jld2file)
    fdict
end

function make_lineage_xmls(
    eco::String, trial::Int, t::Int, 
    domains::Dict{Tuple{String, String}, <:Domain}, 
    prunecfg::PruneCfg = ModesPruneRecordCfg(),
)
    fdict = pfilter_nostats(eco, trial, t, domains, prunecfg)
    savedir = joinpath(ENV["DATA_DIR"], "$eco-$trial") 
    if !isdir(savedir)
        mkdir(savedir)
    else 
        rm(savedir, recursive=true)
        mkdir(savedir)
    end
    for (spid, species_records) in fdict
        final_guy = first(last(species_records))
        lineage = get_lineage(eco, trial, spid, Int(final_guy.ikey.iid), 49950)
        filter_records!(lineage, species_records)
        full_genos = [first(record).prunegenos["full"].geno for record in species_records]
        hop_genos = [first(record).prunegenos["hopcroft"].geno for record in species_records]
        age_genos = [first(record).prunegenos["age"].geno for record in species_records]
        save_fsms(full_genos, "$savedir/$spid-full")
        save_fsms(hop_genos, "$savedir/$spid-hop")
        save_fsms(age_genos, "$savedir/$spid-age")
        doit("$savedir/$spid-full", "$savedir/$spid-full.csv")
        doit("$savedir/$spid-hop", "$savedir/$spid-hop.csv")
        doit("$savedir/$spid-age", "$savedir/$spid-age.csv")
    end
end


function adaptive_prune_lineage(
    eco::String, 
    trial::Int,
    domains::Dict{Tuple{String, String}, <:Domain},
    prunecfg::PruneCfg,
)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    spids = keys(jld2file["arxiv/1/species"])
    pftags = Dict(
        spid => deserialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "tags", "$spid-$trial.jls"))
        for spid in spids
    )
    fdict = Dict(
        spid => pfilter(
            jld2file, 
            spid, 
            pftags[spid], 
            t, 
            filter(d -> spid ∈ first(d), domains), 
            prunecfg
        ) 
        for spid in spids
    )
    close(jld2file)
    fdict
end

function prune_lineage(eco::String, trial::Int, lineage_tags::Vector{FilterTag})
    domaindict = Dict(
        "coop" => Dict(
            ("host", "symbiote") => LingPredGame(MatchCoop())
        ),
        "ctrl" => Dict(
            ("ctrl1", "ctrl2") => LingPredGame(Control())
        ),
        "comp" => Dict(
            ("host", "parasite") => LingPredGame(MatchComp()),
        ),
    )
    domains = domaindict[eco]
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    jld2file = jldopen(joinpath(ecopath, "$trial.jld2"), "r")
    prune_records = ModesPruneRecord[]
    prunecfg = ModesPruneRecordCfg()
    for (gen, lineage_tag) in ProgressBar(enumerate(lineage_tags))
        genphenodict = get_genphenodict(jld2file, gen, lineage_tag.spid, domains)
        records = prunecfg(jld2file, [lineage_tag], genphenodict, domains)
        push!(prune_records, first(records))
    end
    close(jld2file)
    prune_records
end


function doallprune(
    eco::String, trial::Int, species::String, modesgen::Int,
    modelpath::String = "model_finetune.jls",
)
    pftags = deserialize(joinpath(ENV["COEVO_DATA_DIR"], eco, "tags", "$species-$trial.jls"))
    last_iid = first(pftags[modesgen + 1]).iid
    lineage = reverse(get_lineage(eco, trial, species, parse(Int, last_iid), modesgen * 50))
    lineage_tags = [FilterTag(gen, species, string(iid), -1, -1) for (gen, iid) in enumerate(lineage)]
    prune_records = prune_lineage(eco, trial, lineage_tags)
    model = deserialize(modelpath)
    eco_trial_path = joinpath(ENV["DATA_DIR"], "lineages", "$eco-$trial")
    if !isdir(eco_trial_path)
        mkpath(eco_trial_path)
    end
    for prunetype in ["full", "hopcroft", "age"]
        # log stats csv
        fitness = [prune_record.prunegenos[prunetype].fitness for prune_record in prune_records]
        eplen = [prune_record.prunegenos[prunetype].eplen for prune_record in prune_records]
        levdist = [prune_record.prunegenos[prunetype].levdist for prune_record in prune_records]
        coverage = [prune_record.prunegenos[prunetype].coverage for prune_record in prune_records]
        ones = [length(prune_record.prunegenos[prunetype].geno.ones) for prune_record in prune_records]
        zeros = [length(prune_record.prunegenos[prunetype].geno.zeros) for prune_record in prune_records]
        geno_size = [x + y for (x, y) in zip(ones, zeros)]
        df = DataFrame(
            geno_size = geno_size,
            fitness = fitness,
            eplen = eplen,
            levdist = levdist,
            coverage = coverage,
            ones = ones,
            zeros = zeros,
        )
        csv_path = joinpath(eco_trial_path, "$species-$prunetype-stats.csv")
        CSV.write(csv_path, df)

        
        # make graphmls and save to directory
        prune_genos = [prune_record.prunegenos[prunetype].geno for prune_record in prune_records]
        graph_savepath = joinpath(eco_trial_path, "$species-$prunetype")
        mkpath(graph_savepath)
        for (id, geno) in enumerate(prune_genos)
            xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(geno))
            graphml_path = joinpath(graph_savepath, "$(id).graphml")
            save_file(xdoc, graphml_path)
        end
        graphs = load_graphs(graph_savepath)
        sorted_keys = sort(collect(keys(graphs)), lt = (key1, key2) -> begin
            n1 = parse(Int, split(split(key1, "/")[end], ".")[1])
            n2 = parse(Int, split(split(key2, "/")[end], ".")[1])
            return n1 < n2
        end)
        sorted_graphs = [graphs[key] for key in sorted_keys]
        # get and save embeddings csv
        embs = get_embeddings(model, sorted_graphs)
        df = DataFrame(Array(transpose(hcat(embs...))), :auto)
        csv_path = joinpath(eco_trial_path, "$species-$prunetype-embs.csv")
        CSV.write(csv_path, df)
    end
end

function round_dataframe(df::DataFrame, precision::Int)
    # Create a copy to avoid modifying the original DataFrame
    df_rounded = copy(df)

    for col in names(df_rounded)
        if eltype(df_rounded[!, col]) <: AbstractFloat
            df_rounded[!, col] = round.(df_rounded[!, col], digits=precision)
        end
    end
    
    return df_rounded
end

function assign_unique_ids(df::DataFrame)
    # Check if the DataFrame already contains a column named 'id'
    if hasproperty(df, :id)
        throw(ArgumentError("DataFrame already contains a column named 'id'. Please rename it or choose a different name for the unique ID column."))
    end

    # Dictionary to map rows (as tuples) to IDs
    row_to_id = Dict{Tuple, Int}()
    current_id = Ref(1)  # Use a Ref to make it mutable within the inner function

    # Function to get ID for a row, assign a new ID if row is new
    function get_id(row)
        if !haskey(row_to_id, row)
            row_to_id[row] = current_id[]
            current_id[] += 1
        end
        return row_to_id[row]
    end

    # Create a copy of the input DataFrame to avoid modifying the original
    df_copy = copy(df)

    # Append the ID column to the copied DataFrame
    df_copy.id = [get_id(Tuple(row)) for row in eachrow(df_copy)]

    # Make 'id' the first column
    return select(df_copy, :id, Not(:id))
end
