using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.BinomialFunctionGraphs
#using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Complete: CompleteFunctionGraphPhenotypeCreator
#using CoEvo.Phenotypes.FunctionGraphs.Basic
using ProgressBars

println("Starting tests for FunctionGraphs...")
# taken from https://etheses.whiterose.ac.uk/26524/1/thesis_whiterose.pdf page 100

make_edges(source_id::Int, target_ids::Vector{Int}) =
    [Edge(source_id, target_id) for target_id in target_ids]

make_edges(source_id::Int, target_ids::Vector{Tuple{Int, Bool}}) =
    [Edge(source_id, target_id[1], target_id[2]) for target_id in target_ids]

@testset "One-Bit Adder Phenotype" begin
    #genotype = SimpleFunctionGraphGenotype([
    #    Node(1, :INPUT, []),
    #    Node(2, :INPUT, []),
    #    Node(3, :INPUT, []),
    #    Node(4, :XOR, [
    #        Edge(1, 1.0, false), 
    #        Edge(2, 1.0, false)
    #    ]),
    #    Node(5, :AND, [
    #        Edge(1, 1.0, false), 
    #        Edge(2, 1.0, false)
    #    ]),
    #    Node(6, :AND, [
    #        Edge(4, 1.0, false), 
    #        Edge(3, 1.0, false)
    #    ]),
    #    Node(7, :XOR, [
    #        Edge(4, 1.0, false), 
    #        Edge(3, 1.0, false)
    #    ]),
    #    Node(8, :OR, [
    #        Edge(5, 1.0, false), 
    #        Edge(6, 1.0, false)
    #    ]),
    #    Node(9, :OUTPUT, [
    #        Edge(8, 1.0, false)
    #    ]),
    #    Node(10, :OUTPUT, [
    #        Edge(7, 1.0, false)
    #    ])
    #])
    genotype = SimpleFunctionGraphGenotype([
        Node(1, :INPUT), Node(2, :INPUT), Node(3, :INPUT), 
        Node(4, :XOR, make_edges(4, [1, 2])),
        Node(5, :AND, make_edges(5, [1, 2])),
        Node(6, :AND, make_edges(6, [4, 3])),
        Node(7, :XOR, make_edges(7, [4, 3])),
        Node(8, :OR, make_edges(8, [5, 6])),
        Node(9, :OUTPUT, make_edges(9, [8])),
        Node(10, :OUTPUT, make_edges(10, [7]))
    ])


    phenotype_creator = CompleteFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)
    println("\n\nIDS: ", [node.id for node in phenotype.nodes])
    println("FUNC NAMES: ", [node.func.name for node in phenotype.nodes])

    input_outputs = [
        ([0.0, 0.0, 0.0], [0.0, 0.0]),
        ([0.0, 0.0, 1.0], [0.0, 1.0]),
        ([0.0, 1.0, 0.0], [0.0, 1.0]),
        ([0.0, 1.0, 1.0], [1.0, 0.0]),
        ([1.0, 0.0, 0.0], [0.0, 1.0]),
        ([1.0, 0.0, 1.0], [1.0, 0.0]),
        ([1.0, 1.0, 0.0], [1.0, 0.0]),
        ([1.0, 1.0, 1.0], [1.0, 1.0])
    ]

    for (input_values, expected_output) in input_outputs
        println("NEW TEST: $input_values, $expected_output")
        output = act!(phenotype, input_values)
        output = act!(phenotype, input_values)
        @test output == expected_output
        reset!(phenotype)
        #println(output == expected_output)
    end
end

@testset "Logic Gate Phenotype" begin
    #genotype = SimpleFunctionGraphGenotype([
    #    Node(1, :INPUT, []),
    #    Node(2, :INPUT, []),
    #    Node(3, :NAND, [
    #        Edge(1, 1.0, false), 
    #        Edge(2, 1.0, false)
    #    ]),
    #    Node(4, :OR, [
    #        Edge(1, 1.0, false), 
    #        Edge(2, 1.0, false)
    #    ]),
    #    Node(5, :AND, [
    #        Edge(3, 1.0, false), 
    #        Edge(4, 1.0, false)
    #    ]),
    #    Node(6, :OUTPUT, [
    #        Edge(5, 1.0, false)
    #    ])
    #])
    genotype = SimpleFunctionGraphGenotype([
        Node(1, :INPUT), Node(2, :INPUT),
        Node(3, :NAND, make_edges(3, [1, 2])),
        Node(4, :OR, make_edges(4, [1, 2])),
        Node(5, :AND, make_edges(5, [3, 4])),
        Node(6, :OUTPUT, make_edges(6, [5]))
    ])



    phenotype_creator = CompleteFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)

    input_outputs = [
        ([1.0, 1.0], [0.0]),
        ([0.0, 1.0], [1.0]),
        ([1.0, 0.0], [1.0]),
        ([0.0, 0.0], [0.0])
    ]

    for (input_values, expected_output) in input_outputs
        output = act!(phenotype, input_values)
        output = act!(phenotype, input_values)
        println("NEW TEST: $input_values, $expected_output, $output")
        @test output == expected_output
        reset!(phenotype)
    end
end
#
##
@testset "Physics Phenotype" begin
    #genotype = SimpleFunctionGraphGenotype([
    #    Node(1, :INPUT, []),
    #    Node(2, :INPUT, []),
    #    Node(3, :INPUT, []),
    #    Node(4, :INPUT, []),
    #    Node(5, :MULTIPLY, [
    #        Edge(2, 1.0, false), 
    #        Edge(3, 1.0, false)
    #    ]),
    #    Node(6, :MULTIPLY, [
    #        Edge(4, 1.0, false), 
    #        Edge(4, 1.0, false)
    #    ]),
    #    Node(7, :DIVIDE, [
    #        Edge(5, 1.0, false), 
    #        Edge(6, 1.0, false)
    #    ]),
    #    Node(8, :MULTIPLY, [
    #        Edge(1, 1.0, false), 
    #        Edge(7, 1.0, false)
    #    ]),
    #    Node(9, :OUTPUT, [
    #        Edge(8, 1.0, false)
    #    ])
    #])
    genotype = SimpleFunctionGraphGenotype([
        Node(1, :INPUT), Node(2, :INPUT), Node(3, :INPUT), Node(4, :INPUT),
        Node(5, :MULTIPLY, make_edges(5, [2, 3])),
        Node(6, :MULTIPLY, make_edges(6, [4, 4])),
        Node(7, :DIVIDE, make_edges(7, [5, 6])),
        Node(8, :MULTIPLY, make_edges(8, [1, 7])),
        Node(9, :OUTPUT, make_edges(9, [8]))
    ])

    newtons_law_of_gravitation = (g, m1, m2, r) -> (Float32(g) * Float32(m1) * Float32(m2)) / Float32(r)^2

    phenotype_creator = CompleteFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)

    inputs_1 = Float32.([1, 2, 3, 4])
    inputs_2 = Float32.([1, 2, 3, 4])
    inputs_1 = Float32.([(6.674 * 10^-11), 5.972 * 10^24, 1.989 * 10^30, 1.496 * 10^11])
    inputs_2 = Float32.([6.674 * 10^-11, 7.342 * 10^22, 1.989 * 10^30, 3.844 * 10^8])

    input_outputs = [
        (inputs_1, [newtons_law_of_gravitation(inputs_1...)]),
        (inputs_2, [newtons_law_of_gravitation(inputs_2...)])
    ]

    for (input_values, expected_output) in input_outputs
        output = act!(phenotype, input_values)
        output = act!(phenotype, input_values)
        @test isapprox(output[1], expected_output[1]; atol=1e-1)
        reset!(phenotype)
    end
end
#
@testset "Fibonacci Phenotype" begin
    #genotype = SimpleFunctionGraphGenotype([
    #    Node(0, :INPUT, []),
    #    Node(1, :IDENTITY, [Edge(0, 1.0, false)]),
    #    Node(2, :IDENTITY, [Edge(1, 1.0, true)]),
    #    Node(3, :MAXIMUM, [
    #        Edge(5, 1.0, true), 
    #        Edge(1, 1.0, false)
    #    ]),
    #    Node(4, :MULTIPLY, [
    #        Edge(2, 1.0, true), 
    #        Edge(3, 1.0, true)
    #    ]),
    #    Node(5, :ADD, [
    #        Edge(3, 1.0, false),
    #        Edge(4, 1.0, false)
    #    ]),
    #    Node(6, :OUTPUT, [Edge(5, 1.0, false)])
    #])
    genotype = SimpleFunctionGraphGenotype([
        Node(0, :INPUT),
        Node(1, :IDENTITY, make_edges(1, [0])),
        Node(2, :IDENTITY, make_edges(2, [(1, true)])),
        Node(3, :MAXIMUM, make_edges(3, [(5, true), (1, false)])),
        Node(4, :MULTIPLY, make_edges(4, [(2, true), (3, true)])),
        Node(5, :ADD, make_edges(5, [3, 4])),
        Node(6, :OUTPUT, make_edges(6, [5]))
    ])


    phenotype_creator = CompleteFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)
    input_values = [1.0]
    output = act!(phenotype, input_values)
    @test output == [1.0]
    output = act!(phenotype, input_values)
    @test output == [1.0]
    output = act!(phenotype, input_values)
    @test output == [2.0]
    output = act!(phenotype, input_values)
    @test output == [3.0]
    output = act!(phenotype, input_values)
    @test output == [5.0]
    output = act!(phenotype, input_values)
    @test output == [8.0]
    output = act!(phenotype, input_values)
    @test output == [13.0]
end
#
Base.@kwdef mutable struct DummyState <: State
    rng::StableRNG
    individual_id_counter::BasicCounter
    gene_id_counter::BasicCounter
end
#
#
function apply_mutation_storm(
    mutator::BinomialFunctionGraphMutator, 
    genotype::SimpleFunctionGraphGenotype, 
    n_mutations::Int, 
    test_output::Bool = false
)
    state = DummyState(StableRNG(42), BasicCounter(2), BasicCounter(7))
    phenotype_creator = CompleteFunctionGraphPhenotypeCreator()
    output_length_equals_expected = Bool[]
    
    for i in ProgressBar(1:n_mutations)
        #println("i = $i, size = $(length(genotype.hidden_nodes))")
        mutate!(mutator, genotype, state)
        #println("\n$i = $genotype")
        #validate_genotype(genotype)
        if test_output
            println("creating phenotype")
            phenotype = create_phenotype(phenotype_creator, genotype)
            reset!(phenotype)
            input_values = [1.0, -1.0]
            outputs = [round(act!(phenotype, input_values)[1], digits=3) for _ in 1:10]
            if any(isnan, outputs)
                println("NaNs found")
                println(genotype)
                println(phenotype)
                println(input_values)
                println(outputs)
                throw(ErrorException("NaNs found"))
            end
            #println(outputs)
            push!(output_length_equals_expected, length(outputs) == 10)
        end
    end
    @test all(output_length_equals_expected)
end

@testset "Mutation Storm" begin
    genotype_creator = SimpleFunctionGraphGenotypeCreator(
        n_inputs = 2, 
        n_hidden = 1, 
        n_bias = 1,
        n_outputs = 1
    )
    genotype = first(create_genotypes(genotype_creator, StableRNG(1), BasicCounter(1), 1))

    mutator = BinomialFunctionGraphMutator(
        mutation_rates = Dict(
            "CLONE_NODE"    => 0.011,
            "REMOVE_NODE"   => 0.01,
            "MUTATE_NODE"   => 0.025,
            "MUTATE_BIAS"   => 0.05,
            "MUTATE_EDGE"   => 0.025,
            "MUTATE_WEIGHT" => 0.05,
        ),
        validate_genotypes = true
    )
    
    n_mutations = 8_000  # Number of mutations
    apply_mutation_storm(mutator, genotype, n_mutations)
end
### Now, let's write some tests
#@testset "minimize function tests" begin
#    # Define a small genotype for testing.
#    genotype = SimpleFunctionGraphGenotype([
#        Node(1, :INPUT, []),
#        Node(2, :INPUT, []),
#        Node(3, :BIAS, []),
#        Node(4, :ADD, [
#            Edge(1, 1.0, true), 
#            Edge(3, 1.0, true)
#        ]),
#        Node(5, :ADD, [
#            Edge(2, 1.0, true), 
#            Edge(4, 1.0, true)
#        ]),
#        Node(6, :MULTIPLY, [
#            Edge(3, 1.0, true), 
#            Edge(5, 1.0, true)
#        ]),
#        Node(7, :OUTPUT, [
#            Edge(5, 1.0, false)
#        ])
#    ])
#
#    # Minimize the genotype
#    minimized_genotype = minimize(genotype)
#    @test minimized_genotype.input_ids == genotype.input_ids
#    @test minimized_genotype.bias_ids == genotype.bias_ids
#    @test Set(minimized_genotype.hidden_ids) == Set([4, 5])
#    @test minimized_genotype.output_ids == genotype.output_ids
#    
#end
#