using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using LightXML
@everywhere using Random
@everywhere using ProgressBars
@everywhere using CoEvo
@everywhere using StableRNGs
@everywhere using FileIO

# Data structure for the prime graph equivalent of an FSMGeno, 
@everywhere struct FSMPrimeGeno <: Genotype
    start::String
    ones::Set{String}
    zeros::Set{String}
    primes::Set{String} # Set of prime nodes, of the form "{gene_id}P"
    links::Dict{Tuple{String, String}, String}
end

# Converts an FSMGeno to an FSMPrimeGeno, which will have twice the number of nodes
# and a number of new edges equal to this number of new nodes.
# Links are converted to the form (source, label) => target(prime)
# Self links are redirected to the prime node for the original node
# Labels are 0, 1, 01, P, 0P, 1P, 01P
# If both true and false connections lead to a node, 01 is used
# If the connection is to a different node's prime node, the labels are 0, 1, 01
# If it is a self-connection, the label is 0P, 1P, or 01P and leads to one's own prime node
# If there is no self connection, a connection to the prime node is made anyways and labeled P
@everywhere function FSMPrimeGeno(geno::FSMGeno)::FSMPrimeGeno
    # convert to string and generate set of prime nodes
    ones = Set([string(node) for node in geno.ones])
    zeros = Set([string(node) for node in geno.zeros])
    primes = Set([node * "P" for node in union(ones, zeros)])
    links = Dict{Tuple{String, String}, String}()
    start = string(geno.start)
    for node ∈ union(geno.ones, geno.zeros)
        zero_target = string(geno.links[(node, false)])
        one_target = string(geno.links[(node, true)])
        node = string(node)
        zero_points_to_self = zero_target == node
        one_points_to_self = one_target == node
        points_to_same = zero_target == one_target
        if points_to_same && zero_points_to_self && one_points_to_self
            # Create double link to own prime node
            links[(node, "01P")] = node * "P"
        elseif points_to_same && !zero_points_to_self && !one_points_to_self
            # Create double link to other node's prime node
            links[(node, "01")] = zero_target * "P"
            # Create default link to prime node
            links[(node, "P")] = node * "P"
        else
            if zero_points_to_self
                links[(node, "0P")] = node * "P"
            else
                links[(node, "0")] = zero_target * "P" 
            end
            if one_points_to_self
                links[(node, "1P")] = node * "P"
            else
                links[(node, "1")] = one_target * "P"
            end
            if !zero_points_to_self && !one_points_to_self
                links[(node, "P")] = node * "P"
            end
        end
    end
    FSMPrimeGeno(start, ones, zeros, primes, links)
end

# Converts an FSMPrimeGeno to an FSMGeno
# The prime nodes are removed and the links are converted to the form (source, label) => target
function FSMGeno(prime_geno::FSMPrimeGeno, dtype::DataType = Int)
    start = parse(dtype, prime_geno.start)
    ones = Set([parse(dtype, one) for one in prime_geno.ones])
    zeros = Set([parse(dtype, zero) for zero in prime_geno.zeros])
    newlinks = Dict{Tuple{dtype, Bool}, dtype}()
    for ((source, label), target) in prime_geno.links
        source = parse(dtype, source) # parse source node
        target = parse(dtype, target[1:end-1]) # to get nonprime target node, remove "P"
        # if label is 0 or 1, add false or true labeled link
        if label == "0" || label == "0P"
            newlinks[(source, false)] = target
        elseif label == "1" || label == "1P"
            newlinks[(source, true)] = target
        # if label is 01 or 01P, add both false and true labeled link
        elseif label == "01" || label == "01P"
            newlinks[(source, false)] = target
            newlinks[(source, true)] = target
        # ignore single connections to prime nodes
        elseif label == "P"
            continue
        end
    end
    FSMGeno(start, ones, zeros, newlinks)
end

# Parses an FSMPrimeGeno into an XMLDocument in GraphML format
@everywhere function fsmprimegeno_to_xmldoc(geno::FSMPrimeGeno; id::String = "G")
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
    set_attributes(xgraph, Dict("id" => id, "edgedefault" => "undirected"))
    
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

# Generates a trajectory FSMGenos starting from a minimal state, where every 
# n_between_grow generations, the FSM grows by one state.
# Every generation in between, the FSM redirects a link or flips a node label.
@everywhere function evolve_grow_fsm_trajectory(
    n_gen::Int = 50_000, 
    n_between_grow::Int = 10;
    probs1::Dict{Function, Float64} = Dict(
        addstate => 1.0,
        rmstate => 0.0,
        changelink => 0.0,
        changelabel => 0.0
    ),
    probs2::Dict{Function, Float64} = Dict(
        addstate => 0.0,
        rmstate => 0.0,
        changelink => 0.5,
        changelabel => 0.5 
    )
)
    # Initialize tools for running FSM mutation
    sc = SpawnCounter()
    rng = StableRNG(rand(UInt32))
    cfg = FSMIndivConfig(:fsm, Int, false)
    fsm = cfg(rng, sc)  # generate initial FSM
    genos = [fsm.geno]
    for gen in 2:n_gen
        # if gen is divisible by n_between_grow, use probs1 (guaranteed add node), 
        # else use probs2 (equal chance changelabel or changelink)
        m = gen % (n_gen // n_between_grow) == 0 ? 
            LingPredMutator(probs = probs1) : 
            LingPredMutator(probs = probs2)
        fsm = m(rng, sc, fsm)
        push!(genos, fsm.geno)
    end
    genos
end

@everywhere function save_fsm_genos(fsms::Vector{<:FSMGeno}, savedir::String)
    if isdir(savedir)
        rm(savedir, recursive=true)
    end
    mkdir(savedir)
    for (id, fsm) in enumerate(fsms)
        xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(fsm))
        savepath = joinpath(savedir, "$(id).graphml")
        save_file(xdoc, savepath)
    end
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

# This function produces a trajectory of FSMGenos starting from a minimal state and 
# evolving for for n_gen generations, with mutations chosen uniformly at random by default
@everywhere function evolve_rand_fsm_trajectory(;
    n_gen::Int = 50_000,
    probs::Dict{Function, Float64} = Dict(
        addstate => 0.25,
        rmstate => 0.25,
        changelink => 0.25,
        changelabel => 0.25
    ),
    rng = StableRNG(rand(UInt32)),
    cfg = FSMIndivConfig(:fsm, Int, false)
)
    m = LingPredMutator(probs = probs)
    sc = SpawnCounter()
    fsm = cfg(rng, sc) 
    fsms = [fsm]
    for _ in 1:n_gen - 1
        fsm = m(rng, sc, fsm)
        push!(fsms, fsm)
    end
    fsms
end

# This function produces a random FSMGeno sampled from a randomly evolved FSMGeno trajectory
@everywhere function evolve_rand_fsm_geno(;
    rng::AbstractRNG = StableRNG(rand(UInt32)),
    kwargs...
)
    trajectory = evolve_rand_fsm_trajectory(rng=rng; kwargs...)
    rand(rng, trajectory).geno
end


# This takes a vector of job ids, produces corresponding random FSMGenos,
# converts to FSMPrimeGenos, and saves to the savedir as a graphml file
@everywhere function evolve_and_save_rand_fsms(savedir::String, job_ids::Vector{Int}; kwargs...)
    for job_id in job_ids
        geno = evolve_rand_fsm_geno(kwargs...)
        xdoc = fsmprimegeno_to_xmldoc(FSMPrimeGeno(geno))
        graph_savepath = joinpath(savedir, "$job_id.graphml")
        LightXML.save_file(xdoc, graph_savepath)
        free(xdoc)
    end
end

# This function takes the number of jobs and the number of workers and returns a vector of vectors
# of job ids, where each vector of job ids corresponds to a worker
function distribute_job_ids(n_jobs::Int, n_workers::Int)
    job_ids = collect(1:n_jobs)
    chunk_size = div(n_jobs, n_workers)
    extra_jobs = n_jobs % n_workers
    distributed_jobs = [job_ids[(i-1)*chunk_size+1 : i*chunk_size] for i = 1:n_workers]
    # Distribute the extra jobs among the workers
    for i = 1:extra_jobs
        push!(distributed_jobs[i], chunk_size*n_workers + i)
    end
    return distributed_jobs
end

# This is the main driver code for producing random FSMGenos and saving them to graphml files
# in a distributed fashion
@everywhere function parallel_rand_evo_run(
    n_fsms::Int = 1_000_000;
    savedir::String = joinpath(ENV["DATA_DIR"], "rand_fsms"), kwargs...
)
    if isdir(savedir)
        rm(savedir, recursive=true)
    end
    mkpath(savedir)
    n_workers = length(workers())
    job_id_vecs = distribute_job_ids(n_fsms, n_workers)

    futures = [
        @spawnat worker evolve_and_save_rand_fsms(savedir, job_ids) 
            for (worker, job_ids) in zip(workers(), job_id_vecs)
    ]
    for f in futures
        fetch(f)
    end
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
