using StableRNGs: StableRNG
using DataStructures: OrderedDict
using Test

include("../src/CoEvo.jl")
using .CoEvo
using .CoEvo.Utilities.Counters: Counter
using .CoEvo.Ecosystems.Species.Substrates: GeneticPrograms as GP
using .GP: BasicGeneticProgramGenotypeConfiguration
using .GP: BasicGeneticProgramGenotype
using .GP.Genes: ExpressionNodeGene
using .GP.Utilities: protected_division, Terminal
using .GP.Genotypes.Utilities: get_node
using .GP.Genotypes.Mutations: add_function
using .GP.Genotypes.Mutations: remove_function
using .GP.Genotypes.Mutations: splice_function
using .GP.Genotypes.Mutations: swap_node
using .GP.Genotypes.Mutations: inject_noise

BasicGeneticProgramGenotypeConfiguration()(StableRNG(42), Counter())
"""
    dummygeno() -> BasicGeneticProgramGenotype

Create a sample `BasicGeneticProgramGenotype` object for testing purposes.
"""
function dummygeno()
    root = ExpressionNodeGene(1, nothing, +, [2, 3])
    node2 = ExpressionNodeGene(2, 1, 2.0)
    node3 = ExpressionNodeGene(3, 1, 3.0)

    return BasicGeneticProgramGenotype(
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
        1 => ExpressionNodeGene(1, nothing, +, [2, 3]),
        2 => ExpressionNodeGene(2, 1, -, [5, 6]),
        3 => ExpressionNodeGene(3, 1, *, [7, 8]),
        4 => ExpressionNodeGene(4, nothing, protected_division, [9, 10])
    )
    terms = Dict(
        5 => ExpressionNodeGene(5, 2, 5.0),
        6 => ExpressionNodeGene(6, 2, 6.0),
        7 => ExpressionNodeGene(7, 3, 7.0),
        8 => ExpressionNodeGene(8, 3, 8.0),
        9 => ExpressionNodeGene(9, 4, 9.0),
        10 => ExpressionNodeGene(10, 4, 10.0)
    )

    return BasicGeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
end


@testset "Deterministic Mutation Functions" begin
    geno = dummygeno()

    @testset "addfunc" begin
        new_geno = add_function(geno, 4, +, [5, 6], Terminal[2.5, :x])
        @test length(new_geno.functions) == 2
        @test get_node(new_geno, 4).val == +
        @test get_node(new_geno, 5).val == 2.5
        @test get_node(new_geno, 6).val == :x
    end

    @testset "rmfunc" begin
        new_geno = remove_function(geno, 1, 2)
        @test length(new_geno.functions) == 0
        @test length(new_geno.terminals) == 1
        @test !haskey(new_geno.functions, 1)
        @test new_geno.root_id == 2
    end

    @testset "swapnode" begin
        new_geno = swap_node(geno, 2, 3)
        root_node = get_node(new_geno, 1)
        @test root_node.child_ids == [3, 2]

        # Swapping the same node shouldn't change anything
        new_geno2 = swap_node(geno, 2, 2)
        root_node2 = get_node(new_geno2, 1)
        @test root_node2.child_ids == [2, 3]
    end

    @testset "inject_noise" begin
        noise_dict = Dict(2 => 0.5)
        new_geno = inject_noise(geno, noise_dict)
        @test get_node(new_geno, 2).val ≈ 2.5

        # Ensure error is raised for non-float node
        noise_dict_error = Dict(1 => 0.5)
        @test_throws ErrorException inject_noise(geno, noise_dict_error)
    end

    # @testset "conversion to Expr" begin
    #     expr = Base.Expr(geno)
    #     @test expr == Expr(:call, +, 2, 3)
    #     @test eval(expr) == 5.0
    # end

end

@testset "Deterministic Mutation Functions Big" begin
    geno = big_geno()

    @testset "addfunc" begin
        newnode_gid = 11
        newnode_val = protected_division
        newnode_child_gids = [12, 13]
        newnode_child_vals = [12.0, 13.0]

        new_geno = add_function(
            geno, newnode_gid, newnode_val, newnode_child_gids, newnode_child_vals
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








println(dummygeno())