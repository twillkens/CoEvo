using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using LightXML
@everywhere using Random
@everywhere using ProgressBars
@everywhere using CoEvo
@everywhere using StableRNGs
@everywhere using FileIO

@everywhere struct FSMPrimeGeno <: Genotype
    start::String
    ones::Set{String}
    zeros::Set{String}
    primes::Set{String}
    links::Dict{Tuple{String, String}, String}
end


@everywhere function make_prime_graph(geno::FSMGeno)::FSMPrimeGeno
    # Initialize the empty prime graph
    nodes = union(geno.ones, geno.zeros)
    primes = Set{String}([string(node)*"P" for node in nodes])
    ones = Set{String}([string(node) for node in geno.ones])
    zeros = Set{String}([string(node) for node in geno.zeros])
    links = Dict{Tuple{String, String}, String}()
    start = string(geno.start)

    # Add the "primelink" edge between the prime and non-prime nodes
    for node in nodes
        links[(string(node), "P")] = string(node)*"P"
    end

    # Initialize a dict to store links for later processing
    link_temp_dict = Dict{String, Dict{String, String}}()

    # Iterate over the original edges
    for ((source, val), target) in geno.links
        source_str, target_str = string(source), string(target)*"P"
        val_str = val ? "1" : "0"
        
        # Check for self-links
        if source == target
            delete!(links, (source_str, "P"))
            val_str *= "P"
        end
        
        # Add links to link_temp_dict for later processing
        link_temp_dict[source_str] = get(link_temp_dict, source_str, Dict{String, String}())
        link_temp_dict[source_str][val_str] = target_str
    end

    # Process links: if both 0 and 1 (or 0P and 1P) links exist for a source, create 01 (or 01P) link; otherwise keep the original label
    for (source, link_vals_dict) in link_temp_dict
        for (val_str, target) in link_vals_dict
            if source == target
                continue
            end
            if haskey(link_vals_dict, "0") && haskey(link_vals_dict, "1")
                links[(source, "01")] = target
            elseif haskey(link_vals_dict, "0P") && haskey(link_vals_dict, "1P")
                links[(source, "01P")] = target
            else
                links[(source, val_str)] = target
            end
        end
    end

    return FSMPrimeGeno(start, ones, zeros, primes, links)
end

@everywhere function fsmprimegeno_to_xmldoc(geno::FSMPrimeGeno)
    xdoc = XMLDocument()
    xroot = create_root(xdoc, "graphml")
    set_attributes(xroot, Dict("xmlns" => "http://graphml.graphdrawing.org/xmlns",  
                               "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                               "xsi:schemaLocation" => "http://graphml.graphdrawing.org/xmlns 
                                                        http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd"))
    
    # Define keys (GraphML-Attributes) for nodes and edges
    xkey_node = new_child(xroot, "key")
    set_attributes(
        xkey_node, 
        Dict(
            "id" => "d0", 
            "for" => "node", 
            "attr.name" => "type", 
            "attr.type" => "string"
        )
    )
    
    xkey_edge = new_child(xroot, "key")
    set_attributes(
        xkey_edge, 
        Dict(
            "id" => "d1", 
            "for" => "edge", 
            "attr.name" => "label", 
            "attr.type" => "string"
        )
    )
    
    # Create graph
    xgraph = new_child(xroot, "graph")
    set_attributes(xgraph, Dict("id" => "G", "edgedefault" => "undirected"))
    
    # Create nodes
    for node in union(geno.ones, geno.zeros, geno.primes)
        xnode = new_child(xgraph, "node")
        set_attributes(xnode, Dict("id" => node))
        
        xdata = new_child(xnode, "data")
        set_attributes(xdata, Dict("key" => "d0"))
        
        if node == geno.start
            if node in geno.ones
                add_text(xdata, "1_start")
            elseif node in geno.zeros
                add_text(xdata, "0_start")
            end
        elseif node in geno.ones
            add_text(xdata, "1")
        elseif node in geno.zeros
            add_text(xdata, "0")
        elseif node in geno.primes
            add_text(xdata, "P")
        end
    end
    
    # Create edges
    for ((source, label), target) in geno.links
        xedge = new_child(xgraph, "edge")
        set_attributes(xedge, Dict("source" => source, "target" => target))
        
        xdata = new_child(xedge, "data")
        set_attributes(xdata, Dict("key" => "d1"))
        
        add_text(xdata, label)
    end

    return xdoc
end

    

@everywhere function generate_random_fsmgeno(n::Int)
    # Generate random node labels
    nodes = ["$i" for i in 1:n]

    # Randomly select start node
    start = nodes[rand(1:n)]

    # Randomly shuffle node labels
    random_nodes = shuffle(nodes)

    # Calculate the number of ones and zeros based on n
    num_ones = rand(1:n)

    # Assign node labels to ones and zeros sets
    ones = Set(random_nodes[1:num_ones])
    zeros = Set(random_nodes[(num_ones + 1):end])

    # Generate random links between nodes
    links = Dict{Tuple{String, Bool}, String}()
    for node in nodes
        for bit in [false, true]
            # Randomly select target node
            target = nodes[rand(1:n)]
            push!(links, (node, bit) => target)
        end
    end
    FSMGeno(start, ones, zeros, links)
end


function make_random_fsm_xmldoc(n::Int)
    geno = generate_random_fsmgeno(n)
    xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(geno))
    return xdoc
end

# @everywhere function generate_random_fsmprimegenos(top_n::Int = 250, per_n::Int = 400)
#     x = 1
#     if isdir("rand_fsms")
#         rm("rand_fsms", recursive=true)
#     end
#     mkdir("rand_fsms")
#     for n in tqdm(1:top_n)
#         for _ in 1:per_n
#             big = generate_random_fsmgeno(n)
#             hop = minimize(big)
#             xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(hop))
#             save_file(xdoc, "rand_fsms/$(x).graphml")
#             x += 1
#         end
#     end
# end

function generate_random_fsmprimegenos(top_n::Int = 250, per_n::Int = 400)
    if isdir("rand_fsms")
        rm("rand_fsms", recursive=true)
    end
    mkdir("rand_fsms")

    @distributed (+) for n in 1:top_n
        x = (n-1)*per_n + 1
        for _ in 1:per_n
            big = generate_random_fsmgeno(n)
            hop = minimize(big)
            xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(hop))
            save_file(xdoc, "rand_fsms/$(x).graphml")
            x += 1
        end
        return 0
    end
end


@everywhere function ctrl_evo_to_size(n::Int)
    m = LingPredMutator()
    sc = SpawnCounter()
    rng = StableRNG(rand(UInt32))
    cfg = FSMIndivConfig(:fsm, Int, false)
    fsm = cfg(rng, sc) 
    while length(union(fsm.geno.ones, fsm.geno.zeros)) != n
        fsm = m(rng, sc, fsm)
    end
    fsm.geno
end

@everywhere function ctrl_evo_to_size(sizes::UnitRange{Int}, bin_size::Int)
    for n in ProgressBar(sizes)
        for _ in 1:bin_size
            big = ctrl_evo_to_size(n)
            hop = minimize(big)
            xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(hop))
            save_file(xdoc, "data/fsms/$(n).graphml")
        end
    end
end


@everywhere function parallel_task(n::Int, id::Int)
    big = ctrl_evo_to_size(n)
    hop = big
    hop = minimize(big)
    xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(hop))
    save_file(xdoc, "data/fsms/$(n)-$(id).graphml")
end

function parallel_ctrl_evo_to_size(sizes::UnitRange{Int} = 1:250, bin_size::Int = 250)
    if isdir("data/fsms")
        rm("data/fsms", recursive=true)
    end
    mkdir("data/fsms")
    wp = WorkerPool(collect(2:nprocs()))
    
    @sync for n in sizes
        @async for id in 1:bin_size
            # Distribute the tasks across workers using `remotecall`
            remotecall_fetch(parallel_task, wp, n, id)
        end
    end
end

@everywhere function ctrl_evo_to_end(n_gen::Int, rng::AbstractRNG = StableRNG(rand(UInt32)))
    m = LingPredMutator()
    sc = SpawnCounter()
    cfg = FSMIndivConfig(:fsm, Int, false)
    fsms = FSMGeno{Int}[]
    fsm = cfg(rng, sc)
    for _ in 1:n_gen
        fsm = m(rng, sc, fsm)
        push!(fsms, fsm.geno)
    end
    fsms
end

@everywhere function save_fsms(fsms::Vector{<:FSMGeno}, savedir::String = "data/fsms")
    for (id, fsm) in enumerate(fsms)
        hop = minimize(fsm)
        xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(hop))
        savepath = joinpath(savedir, "$(id).graphml")
        save_file(xdoc, savepath)
    end
end

function run_ctrl_evo_to_end(n_gen::Int = 100, savedir::String = "data/fsms", rng::AbstractRNG = StableRNG(rand(UInt32)))
    if isdir(savedir)
        rm(savedir, recursive=true)
    end
    mkdir(savedir)
    fsms = ctrl_evo_to_end(n_gen, rng)
    save_fsms(fsms)
end

function rename_files(directory)
    # Get the list of files in the directory
    files = readdir(directory)
    
    # Extract the size and trial integers from the file names
    file_numbers = [(parse(Int, match(r"(\d+)-", file).match[1:end-1]), parse(Int, match(r"-(\d+)", file).match[2:end])) for file in files]
    
    # Zip the file names and numbers together and sort first by size and then by trial
    sorted_files = sort(collect(zip(files, file_numbers)), by = x -> x[2])
    
    # Iterate over each sorted file
    for (i, file) in enumerate(sorted_files)
        # Generate new file name
        new_file_name = string(i) * ".graphml"
        
        # Full path for old and new file
        old_file = joinpath(directory, file[1])
        new_file = joinpath(directory, new_file_name)
        
        # Rename the file
        mv(old_file, new_file)
    end
end
