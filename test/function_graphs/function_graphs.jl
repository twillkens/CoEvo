using Test

@testset "FunctionGraphs" begin

using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.FunctionGraphs
using CoEvo.Mutators.FunctionGraphs
using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Linearized
using CoEvo.Phenotypes.FunctionGraphs.Basic
using ProgressBars

println("Starting tests for FunctionGraphs...")

FUNCTION_PROBABILITIES = Dict(
    :IDENTITY => 1 / 13,
    :ADD => 1 / 13,
    :SUBTRACT => 1 / 13,
    :MULTIPLY => 1 / 13,
    :DIVIDE => 1 / 13,
    :MAXIMUM => 1 / 13,
    :MINIMUM => 1 / 13,
    :SINE => 1 / 13,
    :COSINE => 1 / 13,
    :ARCTANGENT => 1 / 13,
    :SIGMOID => 1 / 13,
    :TANH => 1 / 13,
    :RELU => 1 / 13
)

@testset "Add Node Tests" begin
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter(6)

    genotype = FunctionGraphGenotype(
        input_node_ids = [1],
        bias_node_ids = [2],
        hidden_node_ids = [3, 4],
        output_node_ids = [5],
        nodes = Dict(
            1 => FunctionGraphNode(1, :INPUT, []),
            2 => FunctionGraphNode(2, :BIAS, []),
            3 => FunctionGraphNode(3, :ADD, [
                FunctionGraphConnection(1, 0.5, false),
                FunctionGraphConnection(2, 0.5, false)
            ]),
            4 => FunctionGraphNode(4, :MULTIPLY, [
                FunctionGraphConnection(3, 0.5, true),
                FunctionGraphConnection(2, 0.5, false)
            ]),
            5 => FunctionGraphNode(5, :OUTPUT, [
                FunctionGraphConnection(4, 1.0, false)
            ]),
        ),
        n_nodes_per_output = 1
    )
    # Create an initial `genotype` object here for testing.

    @testset "Node addition" begin
        new_genotype = fg_add_function(
            random_number_generator, gene_id_counter, genotype, FUNCTION_PROBABILITIES
        )
        @test length(new_genotype.nodes) == length(genotype.nodes) + 1
        @test length(new_genotype.hidden_node_ids) == length(genotype.hidden_node_ids) + 1
    end
    
    @testset "Function selection" begin
        new_genotype = fg_add_function(
            random_number_generator, gene_id_counter, genotype, FUNCTION_PROBABILITIES
        )
        new_id = maximum(keys(new_genotype.nodes))  # Assuming monotonic ids
        new_func = new_genotype.nodes[new_id].func
        @test new_func ∉ [:INPUT, :BIAS, :OUTPUT]
    end

    @testset "Input connections" begin
        new_genotype = fg_add_function(
            random_number_generator, gene_id_counter, genotype, FUNCTION_PROBABILITIES
        )
        new_id = maximum(keys(new_genotype.nodes))
        new_node = new_genotype.nodes[new_id]
        # Test that connections are valid
        for conn in new_node.input_connections
            ids = [
                new_genotype.input_node_ids; 
                new_genotype.bias_node_ids; 
                new_genotype.hidden_node_ids
            ]
            @test conn.input_node_id in ids
            @test conn.weight == 0.0  
            @test conn.is_recurrent == true
        end
    end
end


@testset "Test Node Removal" begin
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter()

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
                FunctionGraphConnection(1, 1.0, false), 
                FunctionGraphConnection(3, 1.0, false)
            ]),
            5 => FunctionGraphNode(5, :ADD, [
                FunctionGraphConnection(2, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            6 => FunctionGraphNode(6, :OUTPUT, [
                FunctionGraphConnection(5, 1.0, false)
            ])
        ),
        n_nodes_per_output = 1
    )

    @testset "Test Deterministic Removal" begin
        # Test deterministic removal
        substitutions = [
            ConnectionRedirectionSpecification(5, 2, 2)
        ]
        new_genotype = fg_remove_function(genotype, 4, substitutions)

        @test !haskey(new_genotype.nodes, 4) # node 4 should be removed
        @test new_genotype.hidden_node_ids == [5] # Only node 5 should be left
        @test new_genotype.nodes[5].input_connections[2].input_node_id == 2 # node 5 should now connect to node 2, not 4
    end

    @testset "Test Illegal Node Removal" begin
        # Trying to remove an input node should throw an error
        @test_throws ErrorException fg_remove_function(genotype, 1, ConnectionRedirectionSpecification[])
    end

    @testset "Test Self-loop Handling" begin
        # Removing node 4 without available redirection options should create a self-loop
        substitutions = [
            ConnectionRedirectionSpecification(5, 2, 5)
        ]
        new_genotype = fg_remove_function(genotype, 4, substitutions)
        
        @test new_genotype.nodes[5].input_connections[end].input_node_id == 5 # self-loop should be created
    end

    @testset "Test Stochastic Removal with Known RNG" begin
        new_genotype = fg_remove_function(random_number_generator, gene_id_counter, genotype, FUNCTION_PROBABILITIES)
    
        # Add specific tests depending on predictable random behavior from the seed
        # Note: You will need to determine the expected behavior based on the RNG seed
        @test !haskey(new_genotype.nodes, 4) || !haskey(new_genotype.nodes, 5)
    end
end

@testset "Test Node Removal" begin
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter()
    genotype = FunctionGraphGenotype(
        input_node_ids = [0],
        bias_node_ids = Int[],
        hidden_node_ids = [1, 2, 3, 4, 5],
        output_node_ids = [6],
        nodes = Dict(
            0 => FunctionGraphNode(0, :INPUT, []),
            1 => FunctionGraphNode(1, :IDENTITY, [
                FunctionGraphConnection(0, 1.0, false)
            ]),
            2 => FunctionGraphNode(2, :IDENTITY, [
                FunctionGraphConnection(1, 1.0, true)
            ]),
            3 => FunctionGraphNode(3, :MAXIMUM, [
                FunctionGraphConnection(1, 1.0, false),
                FunctionGraphConnection(5, 1.0, true), 
            ]),
            4 => FunctionGraphNode(4, :MULTIPLY, [
                FunctionGraphConnection(2, 1.0, true), 
                FunctionGraphConnection(3, 1.0, true)
            ]),
            5 => FunctionGraphNode(5, :ADD, [
                FunctionGraphConnection(3, 1.0, false), 
                FunctionGraphConnection(4, 1.0, false)
            ]),
            6 => FunctionGraphNode(6, :OUTPUT, [
                FunctionGraphConnection(5, 1.0, false)
            ]),
        ),
        n_nodes_per_output = 1
    )

    @test length(keys(genotype.nodes)) == 7

    @testset "Removing Nodes and Validating Connections" begin
        node_to_remove_id = 2

        link_sub_spec_2 = [
            ConnectionRedirectionSpecification(
                node_id = 4, 
                input_connection_index = 1, 
                new_input_node_id = 1
            ),
        ]  # Example: redirect the connection from 2 to 3
        substitutions = get_all_substitutions(genotype, node_to_remove_id, random_number_generator)

        @test Set(substitutions) == Set(link_sub_spec_2)
        mutant = fg_remove_function(genotype, node_to_remove_id, link_sub_spec_2)
        
        @test length(keys(mutant.nodes)) == 6
        @test all(
            connection.input_node_id != node_to_remove_id 
            for connection in mutant.nodes[4].input_connections
        )
        @test mutant.nodes[4].input_connections[1].input_node_id == 1 # node 4 should now connect to node 1, not 2

        node_to_remove_id = 1
        link_sub_spec_1 = [
            ConnectionRedirectionSpecification(
                node_id = 3, 
                input_connection_index = 1, 
                new_input_node_id = 0
            ),
            ConnectionRedirectionSpecification(
                node_id = 4, 
                input_connection_index = 1, 
                new_input_node_id = 0
            ),
        ]  # Example: redirect the connection from 1 to 0

        substitutions = get_all_substitutions(mutant, node_to_remove_id, random_number_generator)

        @test Set(substitutions) == Set(link_sub_spec_1)


        mutant = fg_remove_function(mutant, node_to_remove_id, link_sub_spec_1)
        @test length(keys(mutant.nodes)) == 5

        @test all(
            connection.input_node_id != node_to_remove_id 
            for connection in mutant.nodes[3].input_connections
        )
        @test mutant.nodes[3].input_connections[1].input_node_id == 0 # node 3 should now connect to node 0, not 1
        @test all(
            connection.input_node_id != node_to_remove_id 
            for connection in mutant.nodes[4].input_connections
        )
        @test mutant.nodes[4].input_connections[1].input_node_id == 0 # node 4 should now connect to node 0, not 1
        
        # Similar steps for nodes 1, 3, 4, and 5 with appropriate ConnectionRedirectionSpecification objects
        # ...


        node_to_remove_id = 3
        possible_link_substitution_specifications = [
            ConnectionRedirectionSpecification(
                node_id = 5, 
                input_connection_index = 1, 
                new_input_node_id = 0,
            ),
            ConnectionRedirectionSpecification(
                node_id = 5, 
                input_connection_index = 1, 
                new_input_node_id = 5,
            ),
            ConnectionRedirectionSpecification(
                node_id = 4, 
                input_connection_index = 2, 
                new_input_node_id = 0,
            ),
            ConnectionRedirectionSpecification(
                node_id = 4, 
                input_connection_index = 2, 
                new_input_node_id = 5,
            ),
        ]  # Example: redirect the connection from 3 to 0
        for _ in 1:10
            actual_substitutions = get_all_substitutions(mutant, node_to_remove_id, random_number_generator)
            @test issubset(Set(actual_substitutions), Set(possible_link_substitution_specifications), )
        end
    end
    
    @testset "Error Handling for Invalid Node Removal" begin
        # Attempting to remove input and output nodes - should throw an error
        @test_throws ErrorException fg_remove_function(genotype, 0, ConnectionRedirectionSpecification[])
        @test_throws ErrorException fg_remove_function(genotype, 6, ConnectionRedirectionSpecification[])
    end
end


@testset "Swap Function Tests" begin
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter()

    genotype_example = FunctionGraphGenotype(
        [1], 
        [2], 
        [3, 4],
        [5],
        Dict(
            1 => FunctionGraphNode(1, :INPUT, []),
            2 => FunctionGraphNode(2, :BIAS, []),
            3 => FunctionGraphNode(3, :ADD, [FunctionGraphConnection(1, 1.0, false)]),
            4 => FunctionGraphNode(4, :SUBTRACT, [FunctionGraphConnection(2, 1.0, false)]),
            5 => FunctionGraphNode(5, :OUTPUT, [FunctionGraphConnection(3, 1.0, false)])
        ),
        1
    )
    
    @testset "select_function_with_same_arity" begin
        arity_one_functions = [
            :IDENTITY, :RELU, :TANH, :SIGMOID, :ARCTANGENT, :COSINE, :SINE
        ]
        arity_two_functions = [
            :ADD, :SUBTRACT, :MULTIPLY, :DIVIDE, :MAXIMUM, :MINIMUM
        ]
        eligible_functions = [arity_one_functions ; arity_two_functions]
        arity_one = get_functions_with_arity(1, eligible_functions)
        @test arity_one_functions == [func.name for func in arity_one]
        arity_two = get_functions_with_arity(2, eligible_functions)
        @test arity_two_functions == [func.name for func in arity_two]
    end
    
    @testset "get_genotype_after_swapping_functions" begin
        new_func = :MULTIPLY  # Assume MULTIPLY is a valid function
        swapped_genotype = get_genotype_after_swapping_functions(genotype_example, 3, new_func)
        
        # Check function swap
        @test swapped_genotype.nodes[3].func == new_func  # Function should be updated
        
        # Check the other nodes remain unaffected
        @test swapped_genotype.nodes[4] == genotype_example.nodes[4]
        @test swapped_genotype.nodes[5] == genotype_example.nodes[5]
    end
    
    @testset "swap_function" begin
        swapped_genotype = swap_function(
            random_number_generator, gene_id_counter, genotype_example, FUNCTION_PROBABILITIES
        )
        
        # Check a function was swapped (assuming swap will always change the function)
        swapped_funcs = [node.func for node in values(swapped_genotype.nodes)]
        original_funcs = [node.func for node in values(genotype_example.nodes)]
        @test any(swapped_funcs .!= original_funcs)
        
        # Check node topology remains the same
        swapped_connections = [node.input_connections for node in values(swapped_genotype.nodes)]
        original_connections = [node.input_connections for node in values(genotype_example.nodes)]
        @test swapped_connections == original_connections
    end
end

@testset "Test Connection Redirection" begin
    genotype = FunctionGraphGenotype(
        input_node_ids = [1],
        bias_node_ids = [2],
        hidden_node_ids = [3],
        output_node_ids = [4],
        nodes = Dict(
            1 => FunctionGraphNode(1, :INPUT, []),
            2 => FunctionGraphNode(2, :BIAS, []),
            3 => FunctionGraphNode(3, :ADD, [
                FunctionGraphConnection(1, 1.0, false),
                FunctionGraphConnection(2, 1.0, false)
            ]),
            4 => FunctionGraphNode(4, :OUTPUT, [
                FunctionGraphConnection(3, 1.0, false)
            ])
        ),
        n_nodes_per_output = 1
    )

    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter(5)

    @testset "Deterministic Redirection" begin
        new_input_node_id = 2  
        redirection_spec = ConnectionRedirectionSpecification(
            node_id = 3, 
            input_connection_index = 1, 
            new_input_node_id = new_input_node_id
        )
        new_genotype = redirect_connection(genotype, redirection_spec)
        
        @test new_genotype.nodes[3].input_connections[1].input_node_id == new_input_node_id
        @test new_genotype.nodes[3].input_connections[1].weight == 1.0  # Weight should be unchanged
        @test !new_genotype.nodes[3].input_connections[1].is_recurrent  # Recurrent status should be unchanged
    end
    
    @testset "Stochastic Redirection" begin
        new_genotype = redirect_connection(random_number_generator, gene_id_counter, genotype, FUNCTION_PROBABILITIES)
        is_changed = false
        for (nid, node) in new_genotype.nodes
            for (old_conn, new_conn) in zip(genotype.nodes[nid].input_connections, node.input_connections)
                if old_conn.input_node_id != new_conn.input_node_id
                    is_changed = true
                end
                @test old_conn.weight == new_conn.weight
                @test old_conn.is_recurrent == new_conn.is_recurrent
            end
        end
        @test is_changed
    end
end

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
        phenotype = create_phenotype(LinearizedFunctionGraphPhenotypeCreator(), genotype)
        @test length(phenotype.nodes) == length(genotype.nodes)
        @test phenotype.n_input_nodes == length(genotype.input_node_ids)
        @test phenotype.n_output_nodes == length(genotype.output_node_ids)
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

    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
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

    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
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

    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
    phenotype = create_phenotype(phenotype_creator, genotype)

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

    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
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

using Test

@testset "Inject Noise" begin
    # Create a simple genotype as test case
    random_number_generator = StableRNG(42)
    genotype = FunctionGraphGenotype(
        input_node_ids = [1, 2],
        bias_node_ids = [],
        hidden_node_ids = [3, 4],
        output_node_ids = [5],
        nodes = Dict(
            1 => FunctionGraphNode(1, :INPUT, []),
            2 => FunctionGraphNode(2, :INPUT, []),
            3 => FunctionGraphNode(3, :IDENTITY, [FunctionGraphConnection(1, 0.5, false)]),
            4 => FunctionGraphNode(4, :ADD, [
                FunctionGraphConnection(1, 0.3, false),
                FunctionGraphConnection(2, 0.6, false)
            ]),
            5 => FunctionGraphNode(5, :OUTPUT, [FunctionGraphConnection(3, 0.2, false), FunctionGraphConnection(4, 0.7, false)])
        ),
        n_nodes_per_output = 1
    )

    # Testing deterministic noise injection
    @testset "Deterministic Noise Injection" begin
        noise_map = Dict(3 => [0.1f0], 4 => [-0.1f0, 0.1f0], 5 => [0.05f0, -0.05f0])
        inject_noise!(genotype, noise_map)

        @test genotype.nodes[3].input_connections[1].weight ≈ 0.6
        @test genotype.nodes[4].input_connections[1].weight ≈ 0.2
        @test genotype.nodes[4].input_connections[2].weight ≈ 0.7
        @test genotype.nodes[5].input_connections[1].weight ≈ 0.25
        @test genotype.nodes[5].input_connections[2].weight ≈ 0.65
    end

    # Testing stochastic noise injection
    @testset "Stochastic Noise Injection" begin
        # Storing original weights to compare after noise injection
        original_weights = Dict(
            3 => copy([conn.weight for conn in genotype.nodes[3].input_connections]),
            4 => copy([conn.weight for conn in genotype.nodes[4].input_connections]),
            5 => copy([conn.weight for conn in genotype.nodes[5].input_connections])
        )

        # Injecting stochastic noise
        inject_noise!(random_number_generator, genotype, std_dev=0.2f0)

        # Verifying that weights have changed after noise injection
        @test any(original_weights[3] .!= [conn.weight for conn in genotype.nodes[3].input_connections])
        @test any(original_weights[4] .!= [conn.weight for conn in genotype.nodes[4].input_connections])
        @test any(original_weights[5] .!= [conn.weight for conn in genotype.nodes[5].input_connections])
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
    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
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




println("Finished tests for FunctionGraphs.")

end