export GNARLNodeGene, GNARLConnectionGene, GNARLGeno, minimize, get_req
export GNARLIndiv

struct GNARLNodeGene <: Gene 
    gid::Int
    pos::Float64
end

Base.:(==)(a::GNARLNodeGene, b::GNARLNodeGene) = a.gid == b.gid
Base.hash(a::GNARLNodeGene, h::UInt) = hash(a.gid, h)


struct GNARLConnectionGene <: Gene 
    gid::Int
    origin::Float64
    destination::Float64
    weight::Float64
end

function GNARLConnectionGene(gid::Int, conn::Tuple{Float64, Float64}, weight::Float64)
    GNARLConnectionGene(gid, conn[1], conn[2], weight)
end

Base.:(==)(a::GNARLConnectionGene, b::GNARLConnectionGene) = a.gid == b.gid
Base.hash(a::GNARLConnectionGene, h::UInt) = hash(a.gid, h)

struct GNARLGeno <: Genotype
    inputs::Vector{GNARLNodeGene}
    hidden::Vector{GNARLNodeGene}
    outputs::Vector{GNARLNodeGene}
    connections::Vector{GNARLConnectionGene}
end

function minimize(g::GNARLGeno)
    in_pos = Set(x.pos for x in g.inputs)
    hidden_pos = Set(x.pos for x in g.hidden)
    out_pos = Set(x.pos for x in g.outputs)
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
    in_pos::Set{Float64},
    hidden_pos::Set{Float64},
    out_pos::Set{Float64},
    conn_tups::Set{Tuple{Float64, Float64}},
    from_in::Bool
)
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
    in_pos::Set{Float64}, 
    hidden_pos::Set{Float64}, 
    out_pos::Set{Float64}, 
    conn_tups::Set{Tuple{Float64, Float64}}
)
    in_req_pos = get_req(in_pos, hidden_pos, out_pos, conn_tups, true)
    out_req_pos = get_req(in_pos, hidden_pos, out_pos, conn_tups, false)
    intersect(in_req_pos, out_req_pos)
end

struct GNARLIndiv <: Individual
    ikey::IndivKey
    genotype::GNARLGeno
    pids::Set{UInt32}
end



