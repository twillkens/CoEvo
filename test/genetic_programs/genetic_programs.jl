using Test

@testset "GeneticPrograms" begin

println("Starting tests for GeneticPrograms...")

using CoEvo
using CoEvo.Names
using StableRNGs: StableRNG
using DataStructures: OrderedDict
using .Genotypes.GeneticPrograms
using .Mutators.GeneticPrograms: add_function as gp_add_function
using .Mutators.GeneticPrograms: remove_function as gp_remove_function
using .Mutators.GeneticPrograms: splice_function, swap_node, inject_noise

"""
    dummygeno() -> BasicGeneticProgramGenotype

Create a sample `BasicGeneticProgramGenotype` object for testing purposes.
"""
function dummygeno()
    root = ExpressionNode(1, nothing, +, [2, 3])
    node2 = ExpressionNode(2, 1, 2.0)
    node3 = ExpressionNode(3, 1, 3.0)

    return GeneticProgramGenotype(
        root_id = 1,
        functions = Dict(1 => root),
        terminals = Dict(2 => node2, 3 => node3)
    )
end

"""
    big_geno() -> BasicGeneticProgramGenotype

Create a more complex `BasicGeneticProgramGenotype` object for further testing.
"""
function big_geno()
    funcs = Dict(
        1 => ExpressionNode(1, nothing, +, [2, 3]),
        2 => ExpressionNode(2, 1, -, [5, 6]),
        3 => ExpressionNode(3, 1, *, [7, 8]),
        4 => ExpressionNode(4, nothing, protected_division, [9, 10])
    )
    terms = Dict(
        5 => ExpressionNode(5, 2, 5.0),
        6 => ExpressionNode(6, 2, 6.0),
        7 => ExpressionNode(7, 3, 7.0),
        8 => ExpressionNode(8, 3, 8.0),
        9 => ExpressionNode(9, 4, 9.0),
        10 => ExpressionNode(10, 4, 10.0)
    )

    return GeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
end


@testset "Deterministic Mutation Functions" begin
    genotype = dummygeno()

    @testset "addfunc" begin
        new_geno = gp_add_function(genotype, 4, +, [5, 6], Terminal[2.5, :x])
        @test length(new_geno.functions) == 2
        @test get_node(new_geno, 4).val == +
        @test get_node(new_geno, 5).val == 2.5
        @test get_node(new_geno, 6).val == :x
    end

    @testset "rmfunc" begin
        new_geno = gp_remove_function(genotype, 1, 2)
        @test length(new_geno.functions) == 0
        @test length(new_geno.terminals) == 1
        @test !haskey(new_geno.functions, 1)
        @test new_geno.root_id == 2
    end

    @testset "swapnode" begin
        new_geno = swap_node(genotype, 2, 3)
        root_node = get_node(new_geno, 1)
        @test root_node.child_ids == [3, 2]

        # Swapping the same node shouldn't change anything
        new_geno2 = swap_node(genotype, 2, 2)
        root_node2 = get_node(new_geno2, 1)
        @test root_node2.child_ids == [2, 3]
    end

    @testset "inject_noise" begin
        noise_dict = Dict(2 => 0.5)
        new_geno = inject_noise(genotype, noise_dict)
        @test get_node(new_geno, 2).val ≈ 2.5

        # Ensure error is raised for non-float node
        noise_dict_error = Dict(1 => 0.5)
        @test_throws ErrorException inject_noise(genotype, noise_dict_error)
    end
end

@testset "Deterministic Mutation Functions Big" begin
    genotype = big_geno()

    @testset "addfunc" begin
        newnode_gid = 11
        newnode_val = protected_division
        newnode_child_gids = [12, 13]
        newnode_child_vals = [12.0, 13.0]

        new_geno = gp_add_function(
            genotype, newnode_gid, newnode_val, newnode_child_gids, newnode_child_vals
        )

        # Assert that new function node is added
        @test new_geno.functions[newnode_gid].val == newnode_val
        # Assert new terminals are added
        @test new_geno.terminals[12].val == 12.0
        @test new_geno.terminals[13].val == 13.0
        # Test that parent is set to nothing
        @test new_geno.functions[newnode_gid].parent_id === nothing
        @test length(new_geno.functions) == 5
        @test length(new_geno.terminals) == 8
    end
end

@testset "Phenotype" begin

    function dummygeno_challenge()
        funcs = Dict(
            1 => ExpressionNode(1, nothing, if_less_then_else, [5, 2, 8, 3]),
            2 => ExpressionNode(2, 1, +, [6, 7]),
            3 => ExpressionNode(3, 1, protected_sine, [4]),
            4 => ExpressionNode(4, 3, *, [9, 10]),
            10 => ExpressionNode(10, 4, +, [11, 12]),
        )
        terms = Dict(
            5 => ExpressionNode(5, 1, π),
            6 => ExpressionNode(6, 2, π),
            7 => ExpressionNode(7, 2, :read),
            8 => ExpressionNode(8, 3, :read),
            9 => ExpressionNode(9, 4, :read),
            11 => ExpressionNode(11, 10, :read),
            12 => ExpressionNode(12, 10, -3/2),
        )

        return GeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
    end

    genotype = dummygeno_challenge()

    phenotype_creator = DefaultPhenotypeCreator()

    phenotype = create_phenotype(phenotype_creator, genotype)
    value = act!(phenotype, [0, π, -π])
    @test value ≈ 1.0

end

@testset "Splice" begin

    function splice_geno()
        funcs = Dict(
            1 => ExpressionNode(1, nothing, protected_sine, [2]),
            2 => ExpressionNode(2, 1, +, [3, 4]),
            5 => ExpressionNode(5, nothing, protected_sine, [6]),
            6 => ExpressionNode(6, 5, -, [7, 10]),
            7 => ExpressionNode(7, 6, *, [8, 9]),
        )
        terms = Dict(
            3 => ExpressionNode(3, 2, 1.0),
            4 => ExpressionNode(4, 2, 2.0),
            8 => ExpressionNode(8, 7, 3.0),
            9 => ExpressionNode(9, 7, 4.0),
            10 => ExpressionNode(10, 6, 5.0),
        )

        return GeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
    end

    @testset "splice1" begin
        genotype = splice_geno()
        new_geno = splice_function(genotype, 6, 7, 2)
        expected_funcs = Dict(
            1 => ExpressionNode(1, nothing, protected_sine, [6]),
            2 => ExpressionNode(2, 6, +, [3, 4]),
            5 => ExpressionNode(5, nothing, protected_sine, [7]),
            6 => ExpressionNode(6, 1, -, [2, 10]),
            7 => ExpressionNode(7, 5, *, [8, 9])
        )
        expected_terms = Dict(
            3 => ExpressionNode(3, 2, 1.0),
            4 => ExpressionNode(4, 2, 2.0),
            8 => ExpressionNode(8, 7, 3.0),
            9 => ExpressionNode(9, 7, 4.0),
            10 => ExpressionNode(10, 6, 5.0)
        )
        expected = GeneticProgramGenotype(root_id=1, functions=expected_funcs, terminals=expected_terms)
        @test expected == new_geno
    end
end

end