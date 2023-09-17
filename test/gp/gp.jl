using Test
using Random
using StableRNGs
using CoEvo
using CoEvo.Base.Common
using CoEvo.Base.Reproduction
using CoEvo.Base.Indivs.GP: GPGeno, ExprNode, Terminal, GPMutator, GPIndivCfg, GPIndiv, GPIndivArchiver
using CoEvo.Base.Indivs.GP: get_node, get_child_index, get_ancestors, get_descendents
using CoEvo.Base.Indivs.GP: addfunc, rmfunc, swapnode, inject_noise
using CoEvo.Base.Indivs.GP: pdiv, iflt, psin
using CoEvo.Base.Indivs.GP: pdiv, iflt, psin

function dummygeno()
    # Just a sample GPGeno object to use for tests.
    root = ExprNode(1, nothing, +, [2, 3])
    node2 = ExprNode(2, 1, 2.0)
    node3 = ExprNode(3, 1, 3.0)
    geno = GPGeno(1, Dict(1 => root), Dict(2 => node2, 3 => node3))
    return geno
end

function big_geno()
    funcs = Dict(
        1 => ExprNode(1, nothing, +, [2, 3]),
        2 => ExprNode(2, 1, -, [5, 6]),
        3 => ExprNode(3, 1, *, [7, 8]),
        4 => ExprNode(4, nothing, pdiv, [9, 10]),
    )
    terms = Dict(
        5 => ExprNode(5, 2, 5.0),
        6 => ExprNode(6, 2, 6.0),
        7 => ExprNode(7, 3, 7.0),
        8 => ExprNode(8, 3, 8.0),
        9 => ExprNode(9, 4, 9.0),
        10 => ExprNode(10, 4, 10.0),
    )
    geno = GPGeno(1, funcs, terms)
    return geno
end

@testset "Utility Functions" begin
    geno = dummygeno()

    @testset "get_child_index" begin
        root = get_node(geno, geno.root_gid)
        @test get_child_index(root, get_node(geno, 2)) == 1
        @test get_child_index(root, get_node(geno, 3)) == 2
    end

    @testset "get_ancestors and get_descendents" begin
        @test length(get_ancestors(geno, get_node(geno, 2))) == 1
        @test length(get_descendents(geno, get_node(geno, geno.root_gid))) == 2
    end
end

@testset "Deterministic Mutation Functions" begin
    geno = dummygeno()

    @testset "addfunc" begin
        new_geno = addfunc(geno, 4, +, [5, 6], Terminal[2.5, :x])
        @test length(new_geno.funcs) == 2
        @test get_node(new_geno, 4).val == +
        @test get_node(new_geno, 5).val == 2.5
        @test get_node(new_geno, 6).val == :x
    end

    @testset "rmfunc" begin
        new_geno = rmfunc(geno, 1, 2)
        @test length(new_geno.funcs) == 0
        @test length(new_geno.terms) == 1
        @test !haskey(new_geno.funcs, 1)
        @test new_geno.root_gid == 2
    end

    @testset "swapnode" begin
        new_geno = swapnode(geno, 2, 3)
        root_node = get_node(new_geno, 1)
        @test root_node.child_gids == [3, 2]

        # Swapping the same node shouldn't change anything
        new_geno2 = swapnode(geno, 2, 2)
        root_node2 = get_node(new_geno2, 1)
        @test root_node2.child_gids == [2, 3]
    end

    @testset "inject_noise" begin
        noise_dict = Dict(2 => 0.5)
        new_geno = inject_noise(geno, noise_dict)
        @test get_node(new_geno, 2).val ≈ 2.5

        # Ensure error is raised for non-float node
        noise_dict_error = Dict(1 => 0.5)
        @test_throws ErrorException inject_noise(geno, noise_dict_error)
    end

    @testset "conversion to Expr" begin
        expr = Expr(geno)
        @test expr == Expr(:call, +, 2, 3)
        @test eval(expr) == 5.0
    end

end

@testset "Deterministic Mutation Functions Big" begin
    geno = big_geno()

    @testset "addfunc" begin
        newnode_gid = 11
        newnode_val = pdiv
        newnode_child_gids = [12, 13]
        newnode_child_vals = [12.0, 13.0]

        new_geno = addfunc(geno, newnode_gid, newnode_val, newnode_child_gids, newnode_child_vals)

        # Assert that new function node is added
        @test new_geno.funcs[newnode_gid].val == newnode_val
        # Assert new terminals are added
        @test new_geno.terms[12].val == 12.0
        @test new_geno.terms[13].val == 13.0
        # Test that parent is set to nothing
        @test new_geno.funcs[newnode_gid].parent_gid === nothing
        @test length(new_geno.funcs) == 5
        @test length(new_geno.terms) == 8
    end
end


@testset "Random Mutation Functions" begin
    rng = StableRNG(1234)
    sc = SpawnCounter(2, 4)  # Some dummy spawn counter
    mutator = GPMutator()

    @testset "addfunc" begin
        new_geno = addfunc(rng, sc, mutator, dummygeno())
        @test length(new_geno.funcs) == 2
        newfunc_val = get_node(new_geno, 4).val
        if newfunc_val in [+, -, *]
            @test length(new_geno.terms) == 4
        elseif newfunc_val == iflt
            @test length(new_geno.terms) == 6
        elseif newfunc_val == psin
            @test length(new_geno.terms) == 3
        end
    end

    @testset "rmfunc" begin
        new_geno = rmfunc(rng, mutator, dummygeno())
        @test length(new_geno.funcs) == 0
        @test length(new_geno.terms) == 1
    end

    @testset "swapnode" begin
        geno = dummygeno()
        new_geno = swapnode(geno, 2, 3)
        node2 = get_node(new_geno, 2)
        node3 = get_node(new_geno, 3)
        @test node2.parent_gid == get_node(geno, 2).parent_gid
        @test node3.parent_gid == get_node(geno, 3).parent_gid
        @test get_node(new_geno, 1).child_gids == [3, 2]
    end
end

@testset "Simulate" begin
    @testset "basic" begin
        rng = StableRNG(1234)
        geno = dummygeno()
        expr = Expr(geno)
        @test eval(expr) == 5.0
    end
end

@testset "Spawner" begin
    function testspawner(
        spid::Symbol;
        npop = 10,
    )
        spid => Spawner(
            spid = spid,
            npop = npop,
            icfg = GPIndivCfg(
                spid = spid,
            ),
            phenocfg = DefaultPhenoCfg(),
            replacer = IdentityReplacer(),
            selector = IdentitySelector(),
            recombiner = IdentityRecombiner(),
            mutators = Mutator[],
            archiver = GPIndivArchiver()
        )
    end

    spawner = testspawner(:test)


end