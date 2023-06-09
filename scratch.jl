using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using LightXML
@everywhere using Random
@everywhere using ProgressBars
@everywhere using CoEvo
@everywhere using StableRNGs

@everywhere struct FSMPrimeGeno <: Genotype
    start::String
    ones::Set{String}
    zeros::Set{String}
    primes::Set{String}
    links::Dict{Tuple{String, String}, String}
end

@everywhere function make_prime_graph(geno::FSMGeno)::FSMPrimeGeno
    # Initialize the empty prime graph
    primes = Set{String}([string(node)*"p" for node in union(geno.ones, geno.zeros)])
    ones = Set{String}([string(node) for node in geno.ones])
    zeros = Set{String}([string(node) for node in geno.zeros])
    links = Dict{Tuple{String, String}, String}()
    start = string(geno.start)

    # Add the "primelink" edge between the prime and non-prime nodes
    for node in union(geno.ones, geno.zeros)
        prime_node = string(node)*"p"
        nonprime_node = string(node)
        links[(prime_node, "P")] = nonprime_node
    end

    # Iterate over the original edges
    for ((source, val), target) in geno.links
        # Map the source to the target's prime
        source_str = string(source)
        prime_target = source == target ? string(target) : string(target)*"p" # check for self loop

        # Check if the source already points to the target node
        if haskey(links, (source_str, "1")) && links[(source_str, "1")] == prime_target
            # Remove the "1" label and add the "01" label
            delete!(links, (source_str, "1"))
            links[(source_str, "01")] = prime_target
        elseif haskey(links, (source_str, "0")) && links[(source_str, "0")] == prime_target
            # Remove the "0" label and add the "01" label
            delete!(links, (source_str, "0"))
            links[(source_str, "01")] = prime_target
        else
            # Add the corresponding edge to the prime graph
            if val
                links[(source_str, "1")] = prime_target
            else
                links[(source_str, "0")] = prime_target
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

@everywhere function generate_random_fsmprimegenos(top_n::Int = 250, per_n::Int = 250)
    x = 1
    if isdir("rand_fsms")
        rm("rand_fsms", recursive=true)
    end
    mkdir("rand_fsms")
    mkdir("rand_fsms/hop")
    genoset = Set{FSMGeno}()
    for n in tqdm(1:top_n)
        for _ in 1:per_n
            big = generate_random_fsmgeno(n)
            hop = minimize(big)
            if n < 20
                if hop in genoset
                    continue
                else
                    push!(genoset, hop)
                end
            end
            # xdoc = fsmprimegeno_to_xmldoc(big)
            # save_file(xdoc, "rand_fsms/big/$(x).graphml")
            xdoc = fsmprimegeno_to_xmldoc(make_prime_graph(hop))
            save_file(xdoc, "rand_fsms/hop/$(x).graphml")
            x += 1
        end
        GC.gc()
    end
end



@everywhere function ctrl_evo_to_size(n::Int)
    m = LingPredMutator()
    sc = SpawnCounter()
    rng = StableRNG(42)
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