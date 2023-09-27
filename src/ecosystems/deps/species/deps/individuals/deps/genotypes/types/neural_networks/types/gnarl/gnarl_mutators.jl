
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

function addnode(rng::StableRNG, geno::GNARLGeno)
    node = GNARLNodeGene(sc, rand(rng))
    GNARLGeno(geno.inputs, [geno.hidden; node], geno.outputs, geno.connections)
end

function rmnode(rng::StableRNG, geno::GNARLGeno)
    if length(geno.hidden) == 0
        return geno
    end
    k = rand(rng, geno.hidden)
    GNARLGeno(geno.inputs, filter(x -> x != k, geno.hidden), geno.outputs, geno.connections)
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
    if length(conns) == 0
        return geno
    end
    shuffle!(rng, conns) # Pick random
    i = neuron_pos[conns[1][1]]
    j = neuron_pos[conns[1][2]]
    if j <= 0 # Catching error where destination is an input
        throw("Invalid connection")
    end
    new_conn = GNARLConnectionGene(sc, i, j)
    GNARLGeno(geno.inputs, geno.hidden, geno.outputs, [geno.connections; new_conn])
end

"Remove a random connection"
function rmconn(rng::StableRNG, geno::GNARLGeno)
    if length(ind.genes) == 0
        return geno
    end
    k = rand(rng, geno.connections) # pick a random gene
    GNARLGeno(geno.inputs, geno.hidden, geno.outputs, filter(x -> x != k, geno.connections))
end
