export Neuron, Network, NodeOp, InConn, reset_net!

struct GNARLPhenoNeuron{P <: Real, O <: Real}
    pos::P
    output::Base.RefValue{O}
end

function GNARLPhenoNeuron(pos::Real, output::Real)
    Neuron(pos, Ref(output))
end

function output(neuron::GNARLPhenoNeuron)
    neuron.output[]
end

function output!(neuron::GNARLPhenoNeuron{P, O}, output::O) where {P <: Real, O <: Real}
    neuron.output[] = output
end

struct GNARLPhenoInConn{N <: GNARLPhenoNeuron, W <: Real}
    innode::N
    weight::W
end

struct GNARLPhenoNodeOp{I <: GNARLPhenoInConn, N <: GNARLPhenoNeuron}
    inconns::Vector{I}
    outnode::N
end

struct GNARLPheno{P <: Real, N <: GNARLPhenoNeuron, O <: GNARLPhenoNodeOp}
    ikey::IndivKey
    neurons::Dict{P, N}
    ops::Vector{O}
end

function GNARLPheno(geno::GNARLGeno)
    neuron_pos = [g.pos for g in [geno.inputs; geno.hidden; geno.outputs]]
    neurons = Dict(p => GNARLPhenoNeuron(p, 0.0f0) for p in neuron_pos)
    connmap = Dict(p => filter(c -> c.destination == p, geno.connections) for p in neuron_pos)
    ops = [
        GNARLPhenoNodeOp(
            [GNARLPhenoInConn(neurons[c.origin], c.weight) for c in connmap[p]], 
            neurons[p]
        ) 
        for p in neuron_pos
    ]
    GNARLPheno(geno.ikey, neurons, ops)
end

"Set all outputs to 0"
function reset!(pheno::GNARLPheno)
    for n in values(pheno.neurons)
        output!(n, 0.0f0)
    end
end
