using StableRNGs: StableRNG
using DataStructures: OrderedDict
using Test

#include("../src/CoEvo.jl")
#using .CoEvo
begin @testset "GeneticPrograms" begin

println("Starting tests for GeneticPrograms...")

using .Genotypes.GeneticPrograms.Utilities: Utilities as GPUtils
using .Genotypes.GeneticPrograms.Methods: Manipulate, Traverse
using .Manipulate: add_function, remove_function, splice_function, swap_node, inject_noise
using .Traverse: get_node
using .CoEvo.Ecosystems.Species.Genotypes.GeneticPrograms.Utilities: Utilities as GPUtils 
using .GPUtils: protected_division, Terminal, FuncAlias, protected_sine, if_less_then_else
using .Phenotypes.Interfaces: act!
"""
    dummygeno() -> BasicGeneticProgramGenotype

Create a sample `BasicGeneticProgramGenotype` object for testing purposes.
"""
function dummygeno()
    root = ExpressionNodeGene(1, nothing, +, [2, 3])
    node2 = ExpressionNodeGene(2, 1, 2.0)
    node3 = ExpressionNodeGene(3, 1, 3.0)

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

    return GeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
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

@testset "Phenotype" begin
function dummygeno_challenge()
    funcs = Dict(
        1 => ExpressionNodeGene(1, nothing, if_less_then_else, [5, 2, 8, 3]),
        2 => ExpressionNodeGene(2, 1, +, [6, 7]),
        3 => ExpressionNodeGene(3, 1, protected_sine, [4]),
        4 => ExpressionNodeGene(4, 3, *, [9, 10]),
        10 => ExpressionNodeGene(10, 4, +, [11, 12]),
    )
    terms = Dict(
        5 => ExpressionNodeGene(5, 1, π),
        6 => ExpressionNodeGene(6, 2, π),
        7 => ExpressionNodeGene(7, 2, :read),
        8 => ExpressionNodeGene(8, 3, :read),
        9 => ExpressionNodeGene(9, 4, :read),
        11 => ExpressionNodeGene(11, 10, :read),
        12 => ExpressionNodeGene(12, 10, -3/2),
    )

    return GeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
end

geno = dummygeno_challenge()

phenotype_creator = DefaultPhenotypeCreator()

phenotype = create_phenotype(phenotype_creator, geno)
value = act!(phenotype, [0, π, -π])
@test value ≈ 1.0

end

@testset "Splice" begin

    function splice_geno()
        funcs = Dict(
            1 => ExpressionNodeGene(1, nothing, protected_sine, [2]),
            2 => ExpressionNodeGene(2, 1, +, [3, 4]),
            5 => ExpressionNodeGene(5, nothing, protected_sine, [6]),
            6 => ExpressionNodeGene(6, 5, -, [7, 10]),
            7 => ExpressionNodeGene(7, 6, *, [8, 9]),
        )
        terms = Dict(
            3 => ExpressionNodeGene(3, 2, 1.0),
            4 => ExpressionNodeGene(4, 2, 2.0),
            8 => ExpressionNodeGene(8, 7, 3.0),
            9 => ExpressionNodeGene(9, 7, 4.0),
            10 => ExpressionNodeGene(10, 6, 5.0),
        )

        return GeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
    end

    @testset "splice1" begin
        geno = splice_geno()
        new_geno = splice_function(geno, 6, 7, 2)
        expected_funcs = Dict(
            1 => ExpressionNodeGene(1, nothing, protected_sine, [6]),
            2 => ExpressionNodeGene(2, 6, +, [3, 4]),
            5 => ExpressionNodeGene(5, nothing, protected_sine, [7]),
            6 => ExpressionNodeGene(6, 1, -, [2, 10]),
            7 => ExpressionNodeGene(7, 5, *, [8, 9])
        )
        expected_terms = Dict(
            3 => ExpressionNodeGene(3, 2, 1.0),
            4 => ExpressionNodeGene(4, 2, 2.0),
            8 => ExpressionNodeGene(8, 7, 3.0),
            9 => ExpressionNodeGene(9, 7, 4.0),
            10 => ExpressionNodeGene(10, 6, 5.0)
        )
        expected = GeneticProgramGenotype(root_id=1, functions=expected_funcs, terminals=expected_terms)
        @test expected == new_geno
    end

    # ...[You can follow this structure for the other testsets]

end

@testset "ContinuousPredictionGame" begin

using .PredictionGameOutcomeMetrics: Control

geno1 = GeneticProgramGenotype(
    root_id = 1,
    functions = Dict{Int, ExpressionNodeGene}(),
    terminals = Dict(1 => ExpressionNodeGene(1, nothing, :read) )
)

geno2 = GeneticProgramGenotype(
    root_id = 1,
    functions = Dict(
        1 => ExpressionNodeGene(1, nothing, +, [2, 3]) 
    ),
    terminals = Dict(
        2 => ExpressionNodeGene(2, 1, :read) ,
        3 => ExpressionNodeGene(3, 1, π)
    )
)

pheno1 = create_phenotype(DefaultPhenotypeCreator(), geno1)
pheno2 = create_phenotype(DefaultPhenotypeCreator(), geno2)
outcome_metric = Control()
domain = ContinuousPredictionGameDomain(outcome_metric)
env_creator = TapeEnvironmentCreator(domain, 10)

env = create_environment(env_creator, Phenotype[pheno1, pheno2])

# TODO: concrete test for env
while is_active(env)
    #println("pos1: ", env.pos1, " pos2: ", env.pos2)
    next!(env)
end
#println("tape1: $(env.tape1), tape2: $(env.tape2)")
outcomes = get_outcome_set(env)
@test length(outcomes) == 2

end

println("Finished tests for GeneticPrograms.")

end

end