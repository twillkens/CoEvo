using CoEvo
using CoEvo.Phenotypes.FunctionGraphs.Complete
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.SimpleFunctionGraphs
using CoEvo.Abstract.States
using StableRNGs: StableRNG
using CoEvo.Counters.Basic

genotype = SimpleFunctionGraphGenotype([
    Node(0, :INPUT, []),
    Node(1, :IDENTITY, [Edge(0, 5.0, false)]),
    Node(2, :SINE, [Edge(1, -10.0, false)]),
    Node(3, :COSINE, [Edge(2, 15.0, true)]),  # Recurrent
    Node(4, :EXP, [Edge(3, -20.0, false)]),
    Node(5, :NATURAL_LOG, [Edge(4, 30.0, true)]),  # Recurrent
    Node(6, :TANH, [Edge(5, -40.0, false)]),
    Node(7, :SIGMOID, [Edge(6, 50.0, true)]),  # Recurrent
    Node(8, :RELU, [Edge(7, -60.0, false)]),
    Node(9, :ARCTANGENT, [Edge(8, 70.0, true)]),  # Recurrent
    Node(10, :ADD, [
        Edge(9, -80.0, false),
        Edge(8, 80.0, false)
    ]),
    Node(11, :SUBTRACT, [
        Edge(10, 90.0, false),
        Edge(9, -90.0, true)  # Recurrent
    ]),
    Node(12, :MULTIPLY, [
        Edge(11, 100.0, false),
        Edge(10, -100.0, true)  # Recurrent
    ]),
    Node(13, :DIVIDE, [
        Edge(12, 110.0, false),
        Edge(11, -110.0, true)  # Recurrent
    ]),
    Node(14, :MAXIMUM, [
        Edge(13, 120.0, false),
        Edge(12, -120.0, true)  # Recurrent
    ]),
    Node(15, :MINIMUM, [
        Edge(14, 130.0, false),
        Edge(13, -130.0, false)
    ]),
    Node(16, :MODULO, [
        Edge(15, 140.0, false),
        Edge(14, -140.0, true)  # Recurrent
    ]),
    Node(17, :IF_LESS_THEN_ELSE, [
        Edge(16, 150.0, false),
        Edge(15, -150.0, false),
        Edge(14, 160.0, false),
        Edge(13, -160.0, true)  # Recurrent
    ]),
    Node(18, :OUTPUT, [Edge(17, 170.0, false)])
])

double_genotype = SimpleFunctionGraphGenotype([
    Node(0, :INPUT, []),
    Node(1, :IDENTITY, [Edge(0, 10.0, false)]),
    Node(2, :IDENTITY, [Edge(1, -10.0, false)]),
    Node(3, :SINE, [Edge(2, 20.0, false)]),
    Node(4, :SINE, [Edge(3, -20.0, true)]),  # Recurrent
    Node(5, :COSINE, [Edge(4, 30.0, false)]),
    Node(6, :COSINE, [Edge(5, -30.0, true)]),  # Recurrent
    Node(7, :EXP, [Edge(6, 40.0, false)]),
    Node(8, :EXP, [Edge(7, -40.0, true)]),  # Recurrent
    Node(9, :NATURAL_LOG, [Edge(8, 50.0, false)]),
    Node(10, :NATURAL_LOG, [Edge(9, -50.0, true)]),  # Recurrent
    Node(11, :TANH, [Edge(10, 60.0, false)]),
    Node(12, :TANH, [Edge(11, -60.0, true)]),  # Recurrent
    Node(13, :SIGMOID, [Edge(12, 70.0, false)]),
    Node(14, :SIGMOID, [Edge(13, -70.0, true)]),  # Recurrent
    Node(15, :RELU, [Edge(14, 80.0, false)]),
    Node(16, :RELU, [Edge(15, -80.0, true)]),  # Recurrent
    Node(17, :ARCTANGENT, [Edge(16, 90.0, false)]),
    Node(18, :ARCTANGENT, [Edge(17, -90.0, true)]),  # Recurrent
    Node(19, :ADD, [
        Edge(17, 100.0, false)
        Edge(18, 100.0, false)
    ]),
    Node(20, :ADD, [
        Edge(19, -100.0, false),
        Edge(18, 100.0, false)
    ]),
    Node(21, :SUBTRACT, [
        Edge(20, 110.0, false),
        Edge(19, -110.0, false)
    ]),
    Node(22, :SUBTRACT, [
        Edge(21, 120.0, false),
        Edge(20, -120.0, false)
    ]),
    Node(23, :MULTIPLY, [
        Edge(22, 130.0, false),
        Edge(21, -130.0, false)
    ]),
    Node(24, :MULTIPLY, [
        Edge(23, 140.0, false),
        Edge(22, -140.0, false)
    ]),
    Node(25, :DIVIDE, [
        Edge(24, 150.0, false),
        Edge(23, -150.0, false)
    ]),
    Node(26, :DIVIDE, [
        Edge(25, 160.0, false),
        Edge(24, -160.0, false)
    ]),
    Node(27, :MAXIMUM, [
        Edge(26, 170.0, false),
        Edge(25, -170.0, false)
    ]),
    Node(28, :MAXIMUM, [
        Edge(27, 180.0, false),
        Edge(26, -180.0, false)
    ]),
    Node(29, :MINIMUM, [
        Edge(28, 190.0, false),
        Edge(27, -190.0, false)
    ]),
    Node(30, :MINIMUM, [
        Edge(29, 200.0, false),
        Edge(28, -200.0, false)
    ]),
    Node(31, :MODULO, [
        Edge(30, 210.0, false),
        Edge(29, -210.0, false)
    ]),
    Node(32, :MODULO, [
        Edge(31, 220.0, false),
        Edge(30, -220.0, false)
    ]),
    Node(33, :IF_LESS_THEN_ELSE, [
        Edge(32, 230.0, false),
        Edge(31, -230.0, false),
        Edge(30, 240.0, false),
        Edge(29, -240.0, false)
    ]),
    Node(34, :IF_LESS_THEN_ELSE, [
        Edge(33, 250.0, false),
        Edge(32, -250.0, false),
        Edge(31, 260.0, false),
        Edge(30, -260.0, false)
    ]),
    Node(35, :OUTPUT, [Edge(34, 270.0, false)])
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

