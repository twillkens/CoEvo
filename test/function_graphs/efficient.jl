using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.FunctionGraphs
using CoEvo.Mutators.FunctionGraphs
using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Efficient
using CoEvo.Phenotypes.FunctionGraphs.Basic
using ProgressBars

println("Starting tests for FunctionGraphs...")
@testset "Function Graph Phenotype Tests" begin
    genotype = FunctionGraphGenotype(
        input_node_ids  = [1], 
        bias_node_ids   = [2],
        hidden_node_ids = [3], 
        output_node_ids = [4],
        nodes = Dict(
            1 => FunctionGraphNode(1, :INPUT, FunctionGraphConnection[]),
            2 => FunctionGraphNode(2, :BIAS, FunctionGraphConnection[]),
            3 => FunctionGraphNode(3, :ADD, [
                FunctionGraphConnection(1, 1.0, true),
                FunctionGraphConnection(2, 1.0, true),
            ]),
            4 => FunctionGraphNode(4, :OUTPUT, [
                FunctionGraphConnection(3, 1.0, false),
            ])
        ),
        n_nodes_per_output = 1
    )
    
    # Test 1: Initialization of a stateful node from a stateless node
    @testset "Stateful Node Initialization" begin
        stateless_node = FunctionGraphNode(1, :ADD, [FunctionGraphConnection(2, 0.5, false)])
        stateful_node = FunctionGraphStatefulNode(stateless_node)
        @test stateful_node.id == stateless_node.id
        @test stateful_node.func.name == stateless_node.func
        @test stateful_node.input_nodes == []
        @test stateful_node.current_value_set == false
        @test stateful_node.current_value == 0.0
        @test stateful_node.previous_value == 0.0
        @test stateful_node.seeking_output == false
    end
    
    # Test 2: Creation of phenotype from genotype
    @testset "Phenotype Creation" begin
        phenotype = create_phenotype(DefaultPhenotypeCreator(), genotype)
        @test length(phenotype.nodes) == length(genotype.nodes)
        @test phenotype.input_node_ids == genotype.input_node_ids
        @test phenotype.output_node_ids == genotype.output_node_ids
        phenotype = create_phenotype(EfficientFunctionGraphPhenotypeCreator(), genotype)
        @test length(phenotype.nodes) == length(genotype.nodes)
        @test length(phenotype.input_nodes) == length(genotype.input_node_ids)
        @test length(phenotype.output_nodes) == length(genotype.output_node_ids)
    end
end

@testset "Fibonacci Phenotype" begin
    genotype = FunctionGraphGenotype(
        input_node_ids = [0],
        bias_node_ids = Int[],
        hidden_node_ids = [1, 2, 3, 4, 5],
        output_node_ids = [6],
        nodes = Dict(
            6 => FunctionGraphNode(6, :OUTPUT, [
                FunctionGraphConnection(5, 1.0, false)
            ]),
            5 => FunctionGraphNode(5, :ADD, [
                FunctionGraphConnection(3, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            4 => FunctionGraphNode(4, :MULTIPLY, [
                FunctionGraphConnection(2, 1.0, true), 
                FunctionGraphConnection(3, 1.0, true)
            ]),
            3 => FunctionGraphNode(3, :MAXIMUM, [
                FunctionGraphConnection(5, 1.0, true), 
                FunctionGraphConnection(1, 1.0, false)
            ]),
            2 => FunctionGraphNode(2, :IDENTITY, [
                FunctionGraphConnection(1, 1.0, true)
            ]),
            1 => FunctionGraphNode(1, :IDENTITY, [
                FunctionGraphConnection(0, 1.0, false)
            ]),
            0 => FunctionGraphNode(0, :INPUT, [])
        ),
        n_nodes_per_output = 1
    )

    phenotype_creator = EfficientFunctionGraphPhenotypeCreator()
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



@testset "Logic Gate Phenotype" begin
    genotype = FunctionGraphGenotype(
        input_node_ids = [1, 2],
        bias_node_ids = Int[],
        hidden_node_ids = [3, 4, 5],
        output_node_ids = [6],
        nodes = Dict(
            6 => FunctionGraphNode(6, :OUTPUT, [
                FunctionGraphConnection(5, 1.0, false)
            ]),
            5 => FunctionGraphNode(5, :AND, [
                FunctionGraphConnection(3, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            4 => FunctionGraphNode(4, :OR, [
                FunctionGraphConnection(1, 1.0, false), 
                FunctionGraphConnection(2, 1.0, false)
            ]),
            3 => FunctionGraphNode(3, :NAND, [
                FunctionGraphConnection(1, 1.0, false), 
                FunctionGraphConnection(2, 1.0, false)
            ]),
            2 => FunctionGraphNode(2, :INPUT, []),
            1 => FunctionGraphNode(1, :INPUT, [])
        ),
        n_nodes_per_output = 1
    )

    phenotype_creator = EfficientFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)

    input_outputs = [
        ([1.0, 1.0], [0.0]),
        ([0.0, 1.0], [1.0]),
        ([1.0, 0.0], [1.0]),
        ([0.0, 0.0], [0.0])
    ]

    for (input_values, expected_output) in input_outputs
        output = act!(phenotype, input_values)
        @test output == expected_output
    end
end

@testset "Complex Logic Phenotype" begin
    genotype = FunctionGraphGenotype(
        input_node_ids = [1, 2, 3],
        bias_node_ids = Int[],
        hidden_node_ids = [4, 5, 6, 7, 8, 9],
        output_node_ids = [10, 11],
        nodes = Dict(
            11 => FunctionGraphNode(11, :OUTPUT, [
                FunctionGraphConnection(8, 1.0, false)
            ]),
            10 => FunctionGraphNode(10, :OUTPUT, [
                FunctionGraphConnection(9, 1.0, false)
            ]),
            9 => FunctionGraphNode(9, :OR, [
                FunctionGraphConnection(5, 1.0, false), 
                FunctionGraphConnection(6, 1.0, false)
            ]),
            8 => FunctionGraphNode(8, :XOR, [
                FunctionGraphConnection(3, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            7 => FunctionGraphNode(7, :AND, [
                FunctionGraphConnection(3, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            6 => FunctionGraphNode(6, :AND, [
                FunctionGraphConnection(1, 1.0, false), 
                FunctionGraphConnection(2, 1.0, false)
            ]),
            5 => FunctionGraphNode(5, :AND, [
                FunctionGraphConnection(3, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            4 => FunctionGraphNode(4, :XOR, [
                FunctionGraphConnection(1, 1.0, false), 
                FunctionGraphConnection(2, 1.0, false)
            ]),
            3 => FunctionGraphNode(3, :INPUT, []),
            2 => FunctionGraphNode(2, :INPUT, []),
            1 => FunctionGraphNode(1, :INPUT, [])
        ),
        n_nodes_per_output = 1
    )

    phenotype_creator = EfficientFunctionGraphPhenotypeCreator()
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
        @test output == expected_output
        #println(output == expected_output)
    end
end

@testset "Physics Phenotype" begin
    genotype = FunctionGraphGenotype(
        input_node_ids = [1, 2, 3, 4],
        bias_node_ids = Int[],
        hidden_node_ids = [5, 6, 7, 8],
        output_node_ids = [9],
        nodes = Dict(
            9 => FunctionGraphNode(9, :OUTPUT, [
                FunctionGraphConnection(8, 1.0, false)
            ]),
            8 => FunctionGraphNode(8, :MULTIPLY, [
                FunctionGraphConnection(1, 1.0, false), 
                FunctionGraphConnection(7, 1.0, false)
            ]),
            7 => FunctionGraphNode(7, :DIVIDE, [
                FunctionGraphConnection(5, 1.0, false), 
                FunctionGraphConnection(6, 1.0, false)
            ]),
            6 => FunctionGraphNode(6, :MULTIPLY, [
                FunctionGraphConnection(4, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            5 => FunctionGraphNode(5, :MULTIPLY, [
                FunctionGraphConnection(2, 1.0, false), 
                FunctionGraphConnection(3, 1.0, false)
            ]),
            4 => FunctionGraphNode(4, :INPUT, []),
            3 => FunctionGraphNode(3, :INPUT, []),
            2 => FunctionGraphNode(2, :INPUT, []),
            1 => FunctionGraphNode(1, :INPUT, [])
        ),
        n_nodes_per_output = 1
    )

    newtons_law_of_gravitation = (g, m1, m2, r) -> (Float32(g) * Float32(m1) * Float32(m2)) / Float32(r)^2

    phenotype_creator = EfficientFunctionGraphPhenotypeCreator()
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
        @test isapprox(output[1], expected_output[1]; atol=1e-1)
    end
end

function apply_mutation_storm(
    mutator::FunctionGraphMutator, 
    genotype::FunctionGraphGenotype, 
    n_mutations::Int, 
    test_output::Bool = false
)
    random_number_generator = Random.MersenneTwister(rand(UInt64))
    gene_id_counter = BasicCounter(7)
    phenotype_creator = EfficientFunctionGraphPhenotypeCreator()
    output_length_equals_expected = Bool[]

    
    for _ in ProgressBar(1:n_mutations)
        genotype = mutate(mutator, random_number_generator, gene_id_counter, genotype)
        #validate_genotype(genotype)
        if test_output
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
    genotype = FunctionGraphGenotype(
        input_node_ids = [1, 2], 
        bias_node_ids = [3],
        hidden_node_ids = [4, 5],
        output_node_ids = [6],
        nodes = Dict(
            1 => FunctionGraphNode(1, :INPUT, []),
            2 => FunctionGraphNode(2, :INPUT, []),
            3 => FunctionGraphNode(3, :BIAS, []),
            4 => FunctionGraphNode(4, :ADD, [
                FunctionGraphConnection(1, 1.0, true), 
                FunctionGraphConnection(3, 1.0, true)
            ]),
            5 => FunctionGraphNode(5, :ADD, [
                FunctionGraphConnection(2, 1.0, true), 
                FunctionGraphConnection(4, 1.0, true)
            ]),
            6 => FunctionGraphNode(6, :OUTPUT, [
                FunctionGraphConnection(5, 1.0, false)
            ])
        ),
        n_nodes_per_output = 1
    )
    mutator = FunctionGraphMutator() 
    
    n_mutations = 10_000  # Number of mutations
    apply_mutation_storm(mutator, genotype, n_mutations)
end

# Now, let's write some tests
@testset "minimize function tests" begin
    # Define a small genotype for testing.
    test_genotype = FunctionGraphGenotype(
        input_node_ids = [1, 2],
        bias_node_ids = [3],
        hidden_node_ids = [4, 5, 6],
        output_node_ids = [7],
        nodes = Dict(
            1 => FunctionGraphNode(1, :INPUT, []),
            2 => FunctionGraphNode(2, :INPUT, []),
            3 => FunctionGraphNode(3, :BIAS, []),
            4 => FunctionGraphNode(4, :ADD, [FunctionGraphConnection(1, 1.0, false), FunctionGraphConnection(2, 1.0, false)]),
            5 => FunctionGraphNode(5, :SUBTRACT, [FunctionGraphConnection(3, 1.0, false), FunctionGraphConnection(4, 1.0, false)]),
            6 => FunctionGraphNode(6, :MULTIPLY, [FunctionGraphConnection(2, 1.0, false), FunctionGraphConnection(3, 1.0, false)]),  # Not connected to output
            7 => FunctionGraphNode(7, :OUTPUT, [FunctionGraphConnection(5, 1.0, false)])
        ),
        n_nodes_per_output = 1
    )

    # Minimize the genotype
    minimized_genotype = minimize(test_genotype)
    
        
    # Test 1: Ensure that all nodes in the minimized genotype are connected to output
    @test all(id -> id in minimized_genotype.input_node_ids ||
                   id in minimized_genotype.bias_node_ids ||
                   id in minimized_genotype.hidden_node_ids ||
                   id in minimized_genotype.output_node_ids,
              keys(minimized_genotype.nodes)
          )

    # Test 2: The not connected node (id: 6) should be removed after minimization
    @test !haskey(minimized_genotype.nodes, 6)

    # Test 3: Validate the output node(s) should remain the same after minimization
    @test minimized_genotype.output_node_ids == test_genotype.output_node_ids
    
    # Test 4: Ensure nodes in input, bias, hidden, and output node id vectors really exist in the minimized nodes
    @test all(id -> haskey(minimized_genotype.nodes, id),
              vcat(minimized_genotype.input_node_ids, minimized_genotype.bias_node_ids,
                   minimized_genotype.hidden_node_ids, minimized_genotype.output_node_ids)
          )

    # Test 5: Check if input and bias nodes remain unchanged
    @test minimized_genotype.input_node_ids == test_genotype.input_node_ids
    @test minimized_genotype.bias_node_ids == test_genotype.bias_node_ids
    
    # Test 6: Validate that input, bias, and output nodes in minimized genotype are the same as in the original genotype
    @test all(id -> minimized_genotype.nodes[id] == test_genotype.nodes[id],
              vcat(minimized_genotype.input_node_ids, minimized_genotype.bias_node_ids, minimized_genotype.output_node_ids)
          )
    
end