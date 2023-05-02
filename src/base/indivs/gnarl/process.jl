export process!

"Create the network from the individual"

function process!(
    ops::Vector{GNARLPhenoNodeOp},
    dist::Float32,
    comm::Float32,
    cfg::NamedTuple
)
    output!(ops[1].outnode, dist)
    output!(ops[2].outnode, comm)
    output!(ops[3].outnode, 1.0f0)
    connouts = Dict{Tuple{Float32, Float32}, Float32}()
    nodestates = Dict{Float32, Float32}()
    for op in ops[4:end]
        sum = 0.0f0
        for i = eachindex(op.inconns)
            inconn = op.inconns[i]
            connout = output(inconn.innode) * inconn.weight
            sum += connout
            #sum += output(inconn.innode) * inconn.weight
            if cfg.get_connhist
                connouts[(inconn.innode.pos, op.outnode.pos)] = connout
            end
        end
        output!(op.outnode, tanh(2.5f0 * sum))
    end
    if cfg.get_nodehist
        for op in ops
            nodestates[op.outnode.pos] = output(op.outnode)
        end
    end
    output(ops[end - 1].outnode), output(ops[end].outnode), connouts, nodestates
end

# function process_verbose!(ops::Vector{NodeOp},
#                          dist::Float32,
#                          comm::Float32)
#     output!(ops[1].outnode, dist)
#     output!(ops[2].outnode, comm)
#     output!(ops[3].outnode, 1.0f0)
#     connouts = Dict{Tuple{Float32, Float32}, Float32}()
#     nodestates = Dict{Float32, Float32}()
#     for op in ops[4:end]
#         sum = 0.0f0
#         for i = eachindex(op.inconns)
#             inconn = op.inconns[i]
#             connout = output(inconn.innode) * inconn.weight
#             sum += connout
#             #connouts[(inconn.innode.pos, op.outnode.pos)] = connout
#             #push!(connouts, ((inconn.innode.pos, op.outnode.pos), connout))
#         end
#         output!(op.outnode, tanh(2.5f0 * sum))
#     end
#     for op in ops
#         if op.outnode.pos == 1.0f0 || op.outnode.pos == 2.0f0
#             nodestates[op.outnode.pos] = output(op.outnode)
#         end
#     end
#     output(ops[end - 1].outnode), output(ops[end].outnode), connouts, nodestates
# end
# 