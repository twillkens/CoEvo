using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.SimpleFunctionGraphs
#using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Efficient
#using CoEvo.Phenotypes.FunctionGraphs.Basic
using ProgressBars

println("Starting tests for FunctionGraphs...")
# taken from https://etheses.whiterose.ac.uk/26524/1/thesis_whiterose.pdf page 100
@testset "One-Bit Adder Phenotype" begin
    genotype = SimpleFunctionGraphGenotype([
        SimpleFunctionGraphNode(1, :INPUT, []),
        SimpleFunctionGraphNode(2, :INPUT, []),
        SimpleFunctionGraphNode(3, :INPUT, []),
        SimpleFunctionGraphNode(4, :XOR, [
            SimpleFunctionGraphEdge(1, 1.0, false), 
            SimpleFunctionGraphEdge(2, 1.0, false)
        ]),
        SimpleFunctionGraphNode(5, :AND, [
            SimpleFunctionGraphEdge(1, 1.0, false), 
            SimpleFunctionGraphEdge(2, 1.0, false)
        ]),
        SimpleFunctionGraphNode(6, :AND, [
            SimpleFunctionGraphEdge(4, 1.0, false), 
            SimpleFunctionGraphEdge(3, 1.0, false)
        ]),
        SimpleFunctionGraphNode(7, :XOR, [
            SimpleFunctionGraphEdge(4, 1.0, false), 
            SimpleFunctionGraphEdge(3, 1.0, false)
        ]),
        SimpleFunctionGraphNode(8, :OR, [
            SimpleFunctionGraphEdge(5, 1.0, false), 
            SimpleFunctionGraphEdge(6, 1.0, false)
        ]),
        SimpleFunctionGraphNode(9, :OUTPUT, [
            SimpleFunctionGraphEdge(8, 1.0, false)
        ]),
        SimpleFunctionGraphNode(10, :OUTPUT, [
            SimpleFunctionGraphEdge(7, 1.0, false)
        ])
    ])


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
        output = act!(phenotype, input_values)
        @test output == expected_output
        reset!(phenotype)
        #println(output == expected_output)
    end
end

@testset "Logic Gate Phenotype" begin
    genotype = SimpleFunctionGraphGenotype([
        SimpleFunctionGraphNode(1, :INPUT, []),
        SimpleFunctionGraphNode(2, :INPUT, []),
        SimpleFunctionGraphNode(3, :NAND, [
            SimpleFunctionGraphEdge(1, 1.0, false), 
            SimpleFunctionGraphEdge(2, 1.0, false)
        ]),
        SimpleFunctionGraphNode(4, :OR, [
            SimpleFunctionGraphEdge(1, 1.0, false), 
            SimpleFunctionGraphEdge(2, 1.0, false)
        ]),
        SimpleFunctionGraphNode(5, :AND, [
            SimpleFunctionGraphEdge(3, 1.0, false), 
            SimpleFunctionGraphEdge(4, 1.0, false)
        ]),
        SimpleFunctionGraphNode(6, :OUTPUT, [
            SimpleFunctionGraphEdge(5, 1.0, false)
        ])
    ])


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
        output = act!(phenotype, input_values)
        println("NEW TEST: $input_values, $expected_output, $output")
        @test output == expected_output
        reset!(phenotype)
    end
end

#
@testset "Physics Phenotype" begin
    genotype = SimpleFunctionGraphGenotype([
        SimpleFunctionGraphNode(1, :INPUT, []),
        SimpleFunctionGraphNode(2, :INPUT, []),
        SimpleFunctionGraphNode(3, :INPUT, []),
        SimpleFunctionGraphNode(4, :INPUT, []),
        SimpleFunctionGraphNode(5, :MULTIPLY, [
            SimpleFunctionGraphEdge(2, 1.0, false), 
            SimpleFunctionGraphEdge(3, 1.0, false)
        ]),
        SimpleFunctionGraphNode(6, :MULTIPLY, [
            SimpleFunctionGraphEdge(4, 1.0, false), 
            SimpleFunctionGraphEdge(4, 1.0, false)
        ]),
        SimpleFunctionGraphNode(7, :DIVIDE, [
            SimpleFunctionGraphEdge(5, 1.0, false), 
            SimpleFunctionGraphEdge(6, 1.0, false)
        ]),
        SimpleFunctionGraphNode(8, :MULTIPLY, [
            SimpleFunctionGraphEdge(1, 1.0, false), 
            SimpleFunctionGraphEdge(7, 1.0, false)
        ]),
        SimpleFunctionGraphNode(9, :OUTPUT, [
            SimpleFunctionGraphEdge(8, 1.0, false)
        ])
    ])


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
        output = act!(phenotype, input_values)
        @test isapprox(output[1], expected_output[1]; atol=1e-1)
        reset!(phenotype)
    end
end
#
function apply_mutation_storm(
    mutator::SimpleFunctionGraphMutator, 
    genotype::SimpleFunctionGraphGenotype, 
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
    genotype = SimpleFunctionGraphGenotype([
        SimpleFunctionGraphNode(1, :INPUT, []),
        SimpleFunctionGraphNode(2, :INPUT, []),
        SimpleFunctionGraphNode(3, :BIAS, []),
        SimpleFunctionGraphNode(4, :ADD, [
            SimpleFunctionGraphEdge(1, 1.0, true), 
            SimpleFunctionGraphEdge(3, 1.0, true)
        ]),
        SimpleFunctionGraphNode(5, :ADD, [
            SimpleFunctionGraphEdge(2, 1.0, true), 
            SimpleFunctionGraphEdge(4, 1.0, true)
        ]),
        SimpleFunctionGraphNode(6, :OUTPUT, [
            SimpleFunctionGraphEdge(5, 1.0, false)
        ])
    ])

    mutator = SimpleFunctionGraphMutator() 
    
    n_mutations = 10_000  # Number of mutations
    apply_mutation_storm(mutator, genotype, n_mutations)
end

## Now, let's write some tests
#@testset "minimize function tests" begin
#    # Define a small genotype for testing.
#    genotype = SimpleFunctionGraphGenotype([
#        SimpleFunctionGraphNode(1, :INPUT, []),
#        SimpleFunctionGraphNode(2, :INPUT, []),
#        SimpleFunctionGraphNode(3, :BIAS, []),
#        SimpleFunctionGraphNode(4, :ADD, [
#            SimpleFunctionGraphEdge(1, 1.0, true), 
#            SimpleFunctionGraphEdge(3, 1.0, true)
#        ]),
#        SimpleFunctionGraphNode(5, :ADD, [
#            SimpleFunctionGraphEdge(2, 1.0, true), 
#            SimpleFunctionGraphEdge(4, 1.0, true)
#        ]),
#        SimpleFunctionGraphNode(6, :OUTPUT, [
#            SimpleFunctionGraphEdge(5, 1.0, false)
#        ])
#    ])
#
#
#    # Minimize the genotype
#    minimized_genotype = minimize(genotype)
#    
#        
#    # Test 1: Ensure that all nodes in the minimized genotype are connected to output
#    @test all(id -> id in minimized_genotype.input_node_ids ||
#                   id in minimized_genotype.bias_node_ids ||
#                   id in minimized_genotype.hidden_node_ids ||
#                   id in minimized_genotype.output_node_ids,
#              keys(minimized_genotype.nodes)
#          )
#
#    # Test 2: The not connected node (id: 6) should be removed after minimization
#    @test !haskey(minimized_genotype.nodes, 6)
#
#    # Test 3: Validate the output node(s) should remain the same after minimization
#    @test minimized_genotype.output_node_ids == test_genotype.output_node_ids
#    
#    # Test 4: Ensure nodes in input, bias, hidden, and output node id vectors really exist in the minimized nodes
#    @test all(id -> haskey(minimized_genotype.nodes, id),
#              vcat(minimized_genotype.input_node_ids, minimized_genotype.bias_node_ids,
#                   minimized_genotype.hidden_node_ids, minimized_genotype.output_node_ids)
#          )
#
#    # Test 5: Check if input and bias nodes remain unchanged
#    @test minimized_genotype.input_node_ids == test_genotype.input_node_ids
#    @test minimized_genotype.bias_node_ids == test_genotype.bias_node_ids
#    
#    # Test 6: Validate that input, bias, and output nodes in minimized genotype are the same as in the original genotype
#    @test all(id -> minimized_genotype.nodes[id] == test_genotype.nodes[id],
#              vcat(minimized_genotype.input_node_ids, minimized_genotype.bias_node_ids, minimized_genotype.output_node_ids)
#          )
#    
#end