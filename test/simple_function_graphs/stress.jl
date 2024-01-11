using CoEvo
using CoEvo.Phenotypes.FunctionGraphs.Complete
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.SimpleFunctionGraphs
using CoEvo.Abstract.States
using StableRNGs: StableRNG
using CoEvo.Counters.Basic

genotype = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(0, :INPUT, []),
    SimpleFunctionGraphNode(1, :IDENTITY, [SimpleFunctionGraphEdge(0, 5.0, false)]),
    SimpleFunctionGraphNode(2, :SINE, [SimpleFunctionGraphEdge(1, -10.0, false)]),
    SimpleFunctionGraphNode(3, :COSINE, [SimpleFunctionGraphEdge(2, 15.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(4, :EXP, [SimpleFunctionGraphEdge(3, -20.0, false)]),
    SimpleFunctionGraphNode(5, :NATURAL_LOG, [SimpleFunctionGraphEdge(4, 30.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(6, :TANH, [SimpleFunctionGraphEdge(5, -40.0, false)]),
    SimpleFunctionGraphNode(7, :SIGMOID, [SimpleFunctionGraphEdge(6, 50.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(8, :RELU, [SimpleFunctionGraphEdge(7, -60.0, false)]),
    SimpleFunctionGraphNode(9, :ARCTANGENT, [SimpleFunctionGraphEdge(8, 70.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(10, :ADD, [
        SimpleFunctionGraphEdge(9, -80.0, false),
        SimpleFunctionGraphEdge(8, 80.0, false)
    ]),
    SimpleFunctionGraphNode(11, :SUBTRACT, [
        SimpleFunctionGraphEdge(10, 90.0, false),
        SimpleFunctionGraphEdge(9, -90.0, true)  # Recurrent
    ]),
    SimpleFunctionGraphNode(12, :MULTIPLY, [
        SimpleFunctionGraphEdge(11, 100.0, false),
        SimpleFunctionGraphEdge(10, -100.0, true)  # Recurrent
    ]),
    SimpleFunctionGraphNode(13, :DIVIDE, [
        SimpleFunctionGraphEdge(12, 110.0, false),
        SimpleFunctionGraphEdge(11, -110.0, true)  # Recurrent
    ]),
    SimpleFunctionGraphNode(14, :MAXIMUM, [
        SimpleFunctionGraphEdge(13, 120.0, false),
        SimpleFunctionGraphEdge(12, -120.0, true)  # Recurrent
    ]),
    SimpleFunctionGraphNode(15, :MINIMUM, [
        SimpleFunctionGraphEdge(14, 130.0, false),
        SimpleFunctionGraphEdge(13, -130.0, false)
    ]),
    SimpleFunctionGraphNode(16, :MODULO, [
        SimpleFunctionGraphEdge(15, 140.0, false),
        SimpleFunctionGraphEdge(14, -140.0, true)  # Recurrent
    ]),
    SimpleFunctionGraphNode(17, :IF_LESS_THEN_ELSE, [
        SimpleFunctionGraphEdge(16, 150.0, false),
        SimpleFunctionGraphEdge(15, -150.0, false),
        SimpleFunctionGraphEdge(14, 160.0, false),
        SimpleFunctionGraphEdge(13, -160.0, true)  # Recurrent
    ]),
    SimpleFunctionGraphNode(18, :OUTPUT, [SimpleFunctionGraphEdge(17, 170.0, false)])
])

double_genotype = SimpleFunctionGraphGenotype([
    SimpleFunctionGraphNode(0, :INPUT, []),
    SimpleFunctionGraphNode(1, :IDENTITY, [SimpleFunctionGraphEdge(0, 10.0, false)]),
    SimpleFunctionGraphNode(2, :IDENTITY, [SimpleFunctionGraphEdge(1, -10.0, false)]),
    SimpleFunctionGraphNode(3, :SINE, [SimpleFunctionGraphEdge(2, 20.0, false)]),
    SimpleFunctionGraphNode(4, :SINE, [SimpleFunctionGraphEdge(3, -20.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(5, :COSINE, [SimpleFunctionGraphEdge(4, 30.0, false)]),
    SimpleFunctionGraphNode(6, :COSINE, [SimpleFunctionGraphEdge(5, -30.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(7, :EXP, [SimpleFunctionGraphEdge(6, 40.0, false)]),
    SimpleFunctionGraphNode(8, :EXP, [SimpleFunctionGraphEdge(7, -40.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(9, :NATURAL_LOG, [SimpleFunctionGraphEdge(8, 50.0, false)]),
    SimpleFunctionGraphNode(10, :NATURAL_LOG, [SimpleFunctionGraphEdge(9, -50.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(11, :TANH, [SimpleFunctionGraphEdge(10, 60.0, false)]),
    SimpleFunctionGraphNode(12, :TANH, [SimpleFunctionGraphEdge(11, -60.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(13, :SIGMOID, [SimpleFunctionGraphEdge(12, 70.0, false)]),
    SimpleFunctionGraphNode(14, :SIGMOID, [SimpleFunctionGraphEdge(13, -70.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(15, :RELU, [SimpleFunctionGraphEdge(14, 80.0, false)]),
    SimpleFunctionGraphNode(16, :RELU, [SimpleFunctionGraphEdge(15, -80.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(17, :ARCTANGENT, [SimpleFunctionGraphEdge(16, 90.0, false)]),
    SimpleFunctionGraphNode(18, :ARCTANGENT, [SimpleFunctionGraphEdge(17, -90.0, true)]),  # Recurrent
    SimpleFunctionGraphNode(19, :ADD, [
        SimpleFunctionGraphEdge(17, 100.0, false)
        SimpleFunctionGraphEdge(18, 100.0, false)
    ]),
    SimpleFunctionGraphNode(20, :ADD, [
        SimpleFunctionGraphEdge(19, -100.0, false),
        SimpleFunctionGraphEdge(18, 100.0, false)
    ]),
    SimpleFunctionGraphNode(21, :SUBTRACT, [
        SimpleFunctionGraphEdge(20, 110.0, false),
        SimpleFunctionGraphEdge(19, -110.0, false)
    ]),
    SimpleFunctionGraphNode(22, :SUBTRACT, [
        SimpleFunctionGraphEdge(21, 120.0, false),
        SimpleFunctionGraphEdge(20, -120.0, false)
    ]),
    SimpleFunctionGraphNode(23, :MULTIPLY, [
        SimpleFunctionGraphEdge(22, 130.0, false),
        SimpleFunctionGraphEdge(21, -130.0, false)
    ]),
    SimpleFunctionGraphNode(24, :MULTIPLY, [
        SimpleFunctionGraphEdge(23, 140.0, false),
        SimpleFunctionGraphEdge(22, -140.0, false)
    ]),
    SimpleFunctionGraphNode(25, :DIVIDE, [
        SimpleFunctionGraphEdge(24, 150.0, false),
        SimpleFunctionGraphEdge(23, -150.0, false)
    ]),
    SimpleFunctionGraphNode(26, :DIVIDE, [
        SimpleFunctionGraphEdge(25, 160.0, false),
        SimpleFunctionGraphEdge(24, -160.0, false)
    ]),
    SimpleFunctionGraphNode(27, :MAXIMUM, [
        SimpleFunctionGraphEdge(26, 170.0, false),
        SimpleFunctionGraphEdge(25, -170.0, false)
    ]),
    SimpleFunctionGraphNode(28, :MAXIMUM, [
        SimpleFunctionGraphEdge(27, 180.0, false),
        SimpleFunctionGraphEdge(26, -180.0, false)
    ]),
    SimpleFunctionGraphNode(29, :MINIMUM, [
        SimpleFunctionGraphEdge(28, 190.0, false),
        SimpleFunctionGraphEdge(27, -190.0, false)
    ]),
    SimpleFunctionGraphNode(30, :MINIMUM, [
        SimpleFunctionGraphEdge(29, 200.0, false),
        SimpleFunctionGraphEdge(28, -200.0, false)
    ]),
    SimpleFunctionGraphNode(31, :MODULO, [
        SimpleFunctionGraphEdge(30, 210.0, false),
        SimpleFunctionGraphEdge(29, -210.0, false)
    ]),
    SimpleFunctionGraphNode(32, :MODULO, [
        SimpleFunctionGraphEdge(31, 220.0, false),
        SimpleFunctionGraphEdge(30, -220.0, false)
    ]),
    SimpleFunctionGraphNode(33, :IF_LESS_THEN_ELSE, [
        SimpleFunctionGraphEdge(32, 230.0, false),
        SimpleFunctionGraphEdge(31, -230.0, false),
        SimpleFunctionGraphEdge(30, 240.0, false),
        SimpleFunctionGraphEdge(29, -240.0, false)
    ]),
    SimpleFunctionGraphNode(34, :IF_LESS_THEN_ELSE, [
        SimpleFunctionGraphEdge(33, 250.0, false),
        SimpleFunctionGraphEdge(32, -250.0, false),
        SimpleFunctionGraphEdge(31, 260.0, false),
        SimpleFunctionGraphEdge(30, -260.0, false)
    ]),
    SimpleFunctionGraphNode(35, :OUTPUT, [SimpleFunctionGraphEdge(34, 270.0, false)])
])

Base.@kwdef mutable struct DummyState <: State
    rng::StableRNG
    individual_id_counter::BasicCounter
    gene_id_counter::BasicCounter
end

state = DummyState(StableRNG(abs(rand(Int))), BasicCounter(2), BasicCounter(7))
mutator = SimpleFunctionGraphMutator(max_mutations = 1, mutation_weights = Dict(:add_node! => 0.0, :remove_node! => 0.0, :mutate_node! => 1.0, :mutate_edge! => 1.0))

for m in 1:10000
    mutate!(mutator, double_genotype, state)
    phenotype = create_phenotype(CompleteFunctionGraphPhenotypeCreator(), double_genotype, 1)
    for i in 1:10000
        x = act!(phenotype, [rand(Float32) * 10, rand(Float32) * 10])
        print(first(x), ", ")
    end
    println()
end

