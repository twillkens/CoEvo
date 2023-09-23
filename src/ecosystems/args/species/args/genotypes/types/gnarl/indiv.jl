export GNARLNodeGene, GNARLConnectionGene, GNARLGeno, minimize, get_req
export GNARLIndiv

struct GNARLNodeGene{P <: Real} <: Gene 
    gid::Int
    pos::P
end

Base.:(==)(a::GNARLNodeGene, b::GNARLNodeGene) = a.gid == b.gid
Base.hash(a::GNARLNodeGene, h::UInt) = hash(a.gid, h)

function GNARLNodeGene(sc::SpawnCounter, pos::Real)
    GNARLNodeGene(gid!(sc), pos)
end

function GNARLNodeGene(rng::AbstractRNG, sc::SpawnCounter)
    GNARLNodeGene(sc, rand(rng))
end

struct GNARLConnectionGene{P <: Real, W <: Real} <: Gene 
    gid::Int
    origin::P
    destination::P
    weight::W
end

function GNARLConnectionGene(gid::Int, conn::Tuple{Float64, Float64}, weight::Float64)
    GNARLConnectionGene(gid, conn[1], conn[2], weight)
end

function GNARLConnectionGene(sc::SpawnCounter, origin::Float64, destination::Float64,)
    GNARLConnectionGene(gid!(sc), origin, destination, 0.0)
end

Base.:(==)(a::GNARLConnectionGene, b::GNARLConnectionGene) = a.gid == b.gid
Base.hash(a::GNARLConnectionGene, h::UInt) = hash(a.gid, h)

struct GNARLGeno{N <: GNARLNodeGene, C <: GNARLConnectionGene} <: Genotype
    n_inputs::Int
    n_outputs::Int
    hidden::Vector{N}
    connections::Vector{C}
end

function GNARLGeno(
    n_inputs::Int, n_outputs::Int, postype::Type{P} = Float64, weighttype::Type{W} = Float64
) where {P <: Real, W <: Real}
    GNARLGeno(
        n_inputs, 
        n_outputs, 
        GNARLNodeGene{postype}[],
        GNARLConnectionGene{postype, weighttype}[]
    )
end

function get_inputs(g::GNARLGeno)
    postype = typeof(g.connections).parameters[1]
    Set(postype(i) for i in -g.n_inputs:0)
end

function get_outputs(g::GNARLGeno)
    postype = typeof(g.connections).parameters[1]
    Set(postype(i) for i in 1:g.n_outputs)
end

# the minimize function is used to remove unnecessary hidden nodes 
function minimize(g::GNARLGeno)
    in_pos = get_inputs(g)
    hidden_pos = Set(x.pos for x in g.hidden)
    out_pos = get_outputs(g)
    conn_tups = Set((conn.origin, conn.destination) for conn in g.connections)
    req_hidden_pos = get_req(in_pos, hidden_pos, out_pos, conn_tups)
    min_hidden = filter(x -> x.pos in req_hidden_pos, g.hidden)
    min_pos = union(in_pos, req_hidden_pos, out_pos)
    min_conns = filter(
        x -> (x.origin in min_pos) && (x.destination in min_pos), g.connections
    )
    GNARLGeno(g.inputs, min_hidden, g.outputs, min_conns)
end

function get_req(
    in_pos::Set{P},
    hidden_pos::Set{P},
    out_pos::Set{P},
    conn_tups::Set{Tuple{P, P}},
    from_in::Bool
) where {P <: Real}
    req_pos = from_in ? Set(in_pos) : Set(out_pos)
    s = from_in ? Set(in_pos) : Set(out_pos)
    while true
        t = from_in ? 
            Set(dest for (orig, dest) in conn_tups if (orig in s) && !(dest in s)) : 
            Set(orig for (orig, dest) in conn_tups if (dest in s) && !(orig in s))
        if length(t) == 0
            break
        end
        layer_nodes = Set(x for x in t if !(x in (from_in ? out_pos : in_pos)))
        if length(layer_nodes) == 0
            break
        end
        req_pos = union(req_pos, layer_nodes)
        s = union(s, t)
    end
    Set(h for h in hidden_pos if h in req_pos)
end

function get_req(
    in_pos::Set{P}, 
    hidden_pos::Set{P}, 
    out_pos::Set{P}, 
    conn_tups::Set{Tuple{P, P}}
) where {P <: Real}
    in_req_pos = get_req(in_pos, hidden_pos, out_pos, conn_tups, true)
    out_req_pos = get_req(in_pos, hidden_pos, out_pos, conn_tups, false)
    intersect(in_req_pos, out_req_pos)
end

struct GNARLIndiv{G <: GNARLGeno} <: Individual
    ikey::IndivKey
    genotype::G
    pids::Set{UInt32}
end



