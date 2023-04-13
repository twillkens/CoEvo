
Base.@kwdef struct GNARLMutator <: Mutator
    nchanges::Int = 1
    probs::Dict{Function, Float64} = Dict(
        addnode => 0.25,
        rmnode => 0.25,
        addconn => 0.25,
        rmconn => 0.25
    )
    weight_factor::Float64 = 0.1
end

export mutate_weight, mutate_connect, mutate_neuron, mutate_enabled, mutate

function(m::GNARLMutator)(rng::AbstractRNG, sc::SpawnCounter, indiv::GNARLIndiv,)
    geno = mutate_weights(rng, indiv.geno, m.weight_factor)
    fns = sample(rng, collect(keys(m.probs)), Weights(collect(values(m.probs))), m.nchanges)
    for fn in fns
        geno = fn(rng, sc, geno)
    end
    FSMIndiv(indiv.ikey, geno, indiv.pids)
end

"Mutate the weight of genes"
function mutate_weight(rng::StableRNG, conn::GNARLConnectionGene, weight_factor::Float64)
    GNARLConnectionGene(
        conn.gid, 
        conn.origin, 
        conn.destination, 
        conn.weight + randn(rng) * weight_factor, 
    )
end

function mutate_weights(rng::StableRNG, geno::GNARLGeno, weight_factor::Float64)
    GNARLGeno(
        geno.inputs, 
        geno.hidden, 
        geno.outputs, 
        mutate_weight.(rng, geno.connections, weight_factor)
    )
end

function indexof(a::Array{Float32}, f::Float32)
    findall(x->x==f, a)[1]
end

"Add a connection between 2 random neurons"
function addconn(rng::StableRNG, sc::SpawnCounter, geno::GNARLGeno)
    neuron_pos = [g.pos for g in GNARLNodeGene[geno.inputs; geno.hidden; geno.outputs]]
    nb_neur = length(neuron_pos)
    # Valid neuron pairs
    valid = trues(nb_neur, nb_neur)
    # Remove existing ones
    for conn in geno.connections
        i_origin = indexof(neuron_pos, conn.origin)
        i_dest = indexof(neuron_pos, conn.destination)
        valid[i_origin, i_dest] = false
    end

    for orig in 1:nb_neur
        orig_pos = neuron_pos[orig]
        for dest in 1:nb_neur
            dest_pos = neuron_pos[dest]
            # Remove links towards input neurons and bias neuron
            if dest_pos <= 0
                valid[orig, dest] = false
            end
            # Remove links between output neurons (would not support adding a neuron)
            if orig_pos >= 1 
                valid[orig, dest] = false
            end
        end
    end
    # Filter invalid ones
    conns = findall(valid)
    if length(conns) > 0
        shuffle!(rng, conns) # Pick random
        i = ind.neuron_pos[conns[1][1]]
        j = ind.neuron_pos[conns[1][2]]
        if j <= 0 # Catching error where destination is an input
            return
        end
        if (i, j) in keys(pop.currgenes)
            inno_nb = pop.currgenes[(i, j)]
            g = Gene(inno_nb, i, j)
            ind.genes[inno_nb] = g
        else
            pop.innovation_no += 1
            g = Gene(pop.innovation_no, i, j)
            ind.genes[pop.innovation_no] = g
            pop.currgenes[(i, j)] = pop.innovation_no
        end
    end
end

"Remove a random connection"
function mutate_disconnect!(rng::StableRNG, ind::GNARLIndividual)
    if length(ind.genes)<=1 # Always keep 1 gene
        return
    end
    k = rand(rng, collect(keys(ind.genes))) # pick a random gene
    pop!(ind.genes, k) # remove it
end

function mutate_add_neuron!(rng::StableRNG, ind::GNARLIndividual)
    n = random_position(rng, 0.0f0, 1.0f0)
    push!(ind.neuron_pos, n)
    sort!(ind.neuron_pos)
end

function mutate_delete_neuron!(rng::StableRNG, ind::GNARLIndividual, pop::Population)
    hidden = filter(x -> 0.0f0 < x < 1.0f0, ind.neuron_pos)
    if length(hidden) == 0
        return
    end
    del_key = rand(rng, hidden)
    filter!(x -> x != del_key, ind.neuron_pos)
    to_replace = 0
    for gene in values(ind.genes)
        if del_key == gene.origin || del_key == gene.destination
            delete!(ind.genes, gene.inno_nb)
            to_replace += 1
        end
    end
    for _ in 1:to_replace
        mutate_connect!(rng, ind, pop)
    end
end

function mutate!(rng::StableRNG, ind::GNARLIndividual, pop::Population)
    mutate_weight!(rng, ind, pop.cfg)
    n = 4
    r = rand(rng)
    if r < 1 / n
        mutate_add_neuron!(rng, ind)
    elseif r < 2 / n
        mutate_delete_neuron!(rng, ind, pop)
    elseif r < 3 / n
        mutate_connect!(rng, ind, pop)
    elseif r < 4 / n
        mutate_disconnect!(rng, ind)
    end
end