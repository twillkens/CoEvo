using Test
using Random
using StableRNGs
using Distributed
@everywhere using CoEvo
using CoEvo.Base.Coev
using CoEvo.Base.Common
using CoEvo.Base.Reproduction
using CoEvo.Base.Indivs.GP
using CoEvo.Base.Indivs.GP: GPGeno, ExprNode, Terminal, GPMutator, FuncAlias
using CoEvo.Base.Indivs.GP: GPGenoCfg, GPGenoArchiver
using CoEvo.Base.Indivs.GP: get_node, get_child_index, get_ancestors, get_descendents
using CoEvo.Base.Indivs.GP: addfunc, rmfunc, swapnode, inject_noise, splicefunc
using CoEvo.Base.Indivs.GP: pdiv, iflt, psin

using CoEvo.Domains.SymRegression
using CoEvo.Domains.SymRegression: stir
using CoEvo.Base.Jobs
using CoEvo.Domains.ContinuousPredictionGame


function make_challenge()
    GPGeno(
        root_gid = 1,
        funcs = Dict(
            1 => ExprNode(1, nothing, iflt, [5, 2]),
            2 => ExprNode(2, 1, +, [6, 7]),
            3 => ExprNode(3, 1, psin, [4]),
            4 => ExprNode(4, 3, *, [8, 9]),
        ),
        terms = Dict(
            5 => ExprNode(5, 1, π),
            6 => ExprNode(6, 1, π),
            7 => ExprNode(7, 2, :read),
            8 => ExprNode(8, 1, :read),
            9 => ExprNode(9, 4, :read),
            10 => ExprNode(10, 4, π),
        ),
    )
end



























function spingeno1()
    GPGeno(
        root_gid = 1,
        terms = Dict(
            1 => ExprNode(1, nothing, :read),
        ),
    )
end

function spingeno2()
    GPGeno(
        root_gid = 1,
        funcs = Dict(
            1 => ExprNode(1, nothing, +, [2, 3]),
        ),
        terms = Dict(
            2 => ExprNode(2, 1, :read),
            3 => ExprNode(3, 1, π / 2),
        ),
    )
end

@testset "ContinuousPredictionGame" begin
    @testset "spin" begin
        geno1 = spingeno1()
        geno2 = spingeno2()
        cfg = TapeReaderGPPhenoCfg()
        pheno1 = cfg(IndivKey(:a, 1), geno1)
        pheno2 = cfg(IndivKey(:b, 1), geno2)
        domain = ContinuousPredictionGameDomain()
        obscfg = NullObsConfig()
        outcome = stir(:test, domain, obscfg, pheno1, pheno2)
    end
end

function contpred3mix()
    eco = :continuous_prediction_game
    trial = 1
    seed = 420
    npop = 25
    tsize = 3
    episode_len = 16
    gametype = "coop_match"
    njobs = 8

    function make_spawner(spid::Symbol)
        Spawner(
            spid = spid,
            npop = npop,
            genocfg = GPGenoCfg(),
            phenocfg = TapeReaderGPPhenoCfg(),
            replacer = GenerationalReplacer(n_elite = 0, reverse = true),
            selector = RouletteSelector(μ = npop),
            recombiner = CloneRecombiner(),
            mutators = [mutator],
        )
    end
    
    domain = ContinuousPredictionGameDomain(
        episode_len = episode_len,
        type = gametype,
    )
    order = AllvsAllPlusOrder(
        oid = :continuous_prediction_game, 
        spids = [:host, :para], 
        domain = domain,
        obscfg = NullObsConfig(),
    )

    terms = Dict{Terminal, Int}(:read => 1, 0.0 => 1)
    funcs = Dict{FuncAlias, Int}([
        (+, 2), 
        (-, 2), 
        (*, 2), 
        (pdiv, 2), 
        (psin, 1),
        (iflt, 4),
    ])
    mutator = GPMutator(terminals = terms, functions = funcs)

    host_spawner = make_spawner(:host)
    para_spawner = make_spawner(:para)
    mut_spawner = make_spawner(:mut)
    coev_cfg = CoevConfig(
        eco = eco,
        trial = trial,
        seed = seed,
        orders = [order],
        spawners = [host_spawner, para_spawner],
        jobcfg = ParallelPhenoJobConfig(njobs = njobs),
        arxiv_interval = 0,
        log_interval = 1,
    )

end

@testset "ContinuousPredictionGame" begin
    eco = :continuous_prediction_game
    trial = 1
    seed = 420
    npop = 25
    tsize = 3
    episode_len = 16
    gametype = "coop_match"
    njobs = 8
    
    domain = ContinuousPredictionGameDomain(
        episode_len = episode_len,
        type = gametype,
    )
    order = AllvsAllPlusOrder(
        oid = :continuous_prediction_game, 
        spids = [:host, :para], 
        domain = domain,
        obscfg = NullObsConfig(),
    )

    terms = Dict{Terminal, Int}(:read => 1, 0.0 => 1)
    funcs = Dict{FuncAlias, Int}([
        (+, 2), 
        (-, 2), 
        (*, 2), 
        (pdiv, 2), 
        (psin, 1),
        (iflt, 4),
    ])
    mutator = GPMutator(terminals = terms, functions = funcs)

    host_spawner = Spawner(
        spid = :host,
        npop = npop,
        genocfg = GPGenoCfg(),
        phenocfg = TapeReaderGPPhenoCfg(),
        replacer = GenerationalReplacer(n_elite = 0, reverse = true),
        selector = RouletteSelector(μ = npop),
        #selector = TournamentSelector(
        #    μ = npop,
        #    tsize = 3,
        #),
        recombiner = CloneRecombiner(),
        mutators = [mutator],
    )
    para_spawner = Spawner(
        spid = :para,
        npop = npop,
        genocfg = GPGenoCfg(),
        phenocfg = TapeReaderGPPhenoCfg(),
        replacer = GenerationalReplacer(n_elite = 0, reverse = true),
        selector = RouletteSelector(μ = npop),
        #selector = TournamentSelector(
        #    μ = npop,
        #    tsize = 3,
        #),
        recombiner = CloneRecombiner(),
        mutators = [mutator],
    )


    coev_cfg = CoevConfig(
        eco = eco,
        trial = trial,
        seed = seed,
        orders = [order],
        spawners = [host_spawner, para_spawner],
        jobcfg = ParallelPhenoJobConfig(njobs = njobs),
        arxiv_interval = 0,
        log_interval = 1,
    )

    species = coev_cfg()
    #evolve!(1, 1000, coev_cfg, species)
end


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
        new_geno = rmfunc(rng, sc, mutator, dummygeno())
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

# @testset "Spawner" begin
#     function gp_spawner(
#         spid::Symbol;
#         npop = 10,
#     )
#         Spawner(
#             spid = spid,
#             npop = npop,
#             genocfg = GPGenoCfg(),
#             phenocfg = DefaultPhenoCfg(),
#             replacer = IdentityReplacer(),
#             selector = IdentitySelector(),
#             recombiner = IdentityRecombiner(),
#             mutators = Mutator[],
#             archiver = GPGenoArchiver()
#         )
#     end
#     function sym_spawner(
#         spid::Symbol;
#         npop = 20,
#     )
#         Spawner(
#             spid = spid,
#             npop = npop,
#             genocfg = SymbolicRegressionTestGenoCfg(
#                 point_range = -10:10,
#                 func = x -> x^2
#             ),
#             phenocfg = DefaultPhenoCfg(),
#             replacer = IdentityReplacer(),
#             selector = IdentitySelector(),
#             recombiner = IdentityRecombiner(),
#             mutators = Mutator[],
#             archiver = SymbolicRegressionTestGenoArchiver()
#         )
#     end
#     rng = StableRNG(1234)
#     sc = SpawnCounter(1, 1)
# 
#     spawner = gp_spawner(:test)
#     gp_species = spawner(rng, sc)
#     spawner = sym_spawner(:test)
#     sym_species = spawner(rng, sc)
# end

@testset "Symbolic Regression" begin
    domain = SymbolicRegressionDomain(
        func = x -> x^2 + x + 1,
        symbols = [:x],
    )
    order = AllvsAllPlusOrder(
        oid = :symbolic_regression, 
        spids = [:gp, :sym], 
        domain = domain,
        obscfg = NullObsConfig(),
    )

    terms = Dict{Terminal, Int}(:x => 1, 0.0 => 1)
    funcs = Dict{FuncAlias, Int}([
        (+, 2), 
        (-, 2), 
        (*, 2), 
        (pdiv, 2), 
        (psin, 1),
    ])
    mutator = GPMutator(terminals = terms, functions = funcs)

    gp_spawner = Spawner(
        spid = :gp,
        npop = 200,
        genocfg = GPGenoCfg(),
        replacer = GenerationalReplacer(n_elite = 10),
        selector = TournamentSelector(
            μ = 200,
            tsize = 3,
        ),
        recombiner = CloneRecombiner(),
        mutators = [mutator],
    )

    genocfg = SymbolicRegressionGenoCfg(-10:10,)
    sym_spawner = Spawner(
        spid = :sym,
        npop = 100,
        genocfg = genocfg,
    )


    coev_cfg = CoevConfig(
        eco = :symbolic_regression,
        trial = 1,
        seed = 420,
        orders = [order],
        spawners = [gp_spawner, sym_spawner],
        arxiv_interval = 0,
        log_interval = 1,
    )

    species = coev_cfg()
    evolve!(1, 10, coev_cfg, species)
end

@testset "Splice" begin
    function splice_geno()
        root_gid = 1
        funcs = Dict(
            1 => ExprNode(1, nothing, psin, [2]),
            2 => ExprNode(2, 1, +, [3, 4]),
            5 => ExprNode(5, nothing, psin, [6]),
            6 => ExprNode(6, 5, -, [7, 10]),
            7 => ExprNode(7, 6, *, [8, 9]),
        )
        terms = Dict(
            3 => ExprNode(3, 2, 1.0),
            4 => ExprNode(4, 2, 2.0),
            8 => ExprNode(8, 7, 3.0),
            9 => ExprNode(9, 7, 4.0),
            10 => ExprNode(10, 6, 5.0),
        )

        geno = GPGeno(root_gid, funcs, terms)
        return geno
    end

    @testset "splice1" begin
        geno = splice_geno()
        new_geno = splicefunc(geno, 6, 7, 2)
        expected = GPGeno(
            1,
            Dict(
                1 => ExprNode(1, nothing, psin, [6]),
                2 => ExprNode(2, 6, +, [3, 4]),
                5 => ExprNode(5, nothing, psin, [7]),
                6 => ExprNode(6, 1, -, [2, 10]),
                7 => ExprNode(7, 5, *, [8, 9]),
            ),
            Dict(
                3 => ExprNode(3, 2, 1.0),
                4 => ExprNode(4, 2, 2.0),
                8 => ExprNode(8, 7, 3.0),
                9 => ExprNode(9, 7, 4.0),
                10 => ExprNode(10, 6, 5.0),
            )
        )
        @test expected == new_geno
    end

    @testset "splice2" begin
        geno = splice_geno()
        new_geno = splicefunc(geno, 6, 10, 2)
        expected = GPGeno(
            root_gid = 1,
            funcs = Dict(
                1 => ExprNode(1, nothing, psin, [6]),
                2 => ExprNode(2, 6, +, [3, 4]),
                5 => ExprNode(5, nothing, psin, [10]),
                6 => ExprNode(6, 1, -, [7, 2]),
                7 => ExprNode(7, 6, *, [8, 9]),
            ),
            terms = Dict(
                3 => ExprNode(3, 2, 1.0),
                4 => ExprNode(4, 2, 2.0),
                8 => ExprNode(8, 7, 3.0),
                9 => ExprNode(9, 7, 4.0),
                10 => ExprNode(10, 5, 5.0),
            )
        )
        @test expected == new_geno
    end

    @testset "splice3" begin
        geno = splice_geno()
        new_geno = splicefunc(geno, 6, 9, 2)
        expected = GPGeno(
            root_gid = 1,
            funcs = Dict(
                1 => ExprNode(1, nothing, psin, [6]),
                2 => ExprNode(2, 7, +, [3, 4]),
                5 => ExprNode(5, nothing, psin, [9]),
                6 => ExprNode(6, 1, -, [7, 10]),
                7 => ExprNode(7, 6, *, [8, 2]),
            ),
            terms = Dict(
                3 => ExprNode(3, 2, 1.0),
                4 => ExprNode(4, 2, 2.0),
                8 => ExprNode(8, 7, 3.0),
                9 => ExprNode(9, 5, 4.0),
                10 => ExprNode(10, 6, 5.0),
            )
        )

        @test expected == new_geno
    end

    @testset "splice4" begin
        geno = splice_geno()
        new_geno = splicefunc(geno, 6, 10, 1)
        expected = GPGeno(
            root_gid = 6,
            funcs = Dict(
                1 => ExprNode(1, 6, psin, [2]),
                2 => ExprNode(2, 1, +, [3, 4]),
                5 => ExprNode(5, nothing, psin, [10]),
                6 => ExprNode(6, nothing, -, [7, 1]),
                7 => ExprNode(7, 6, *, [8, 9]),
            ),
            terms = Dict(
                3 => ExprNode(3, 2, 1.0),
                4 => ExprNode(4, 2, 2.0),
                8 => ExprNode(8, 7, 3.0),
                9 => ExprNode(9, 7, 4.0),
                10 => ExprNode(10, 5, 5.0),
            )
        )

        @test expected == new_geno
    end

    @testset "splice5" begin
        geno = splice_geno()
        new_geno = splicefunc(geno, 1, 4, 8)
        expected = GPGeno(
            root_gid = 5,
            funcs = Dict(
                1 => ExprNode(1, 7, psin, [2]),
                2 => ExprNode(2, 1, +, [3, 8]),
                5 => ExprNode(5, nothing, psin, [6]),
                6 => ExprNode(6, 5, -, [7, 10]),
                7 => ExprNode(7, 6, *, [1, 9]),
            ),
            terms = Dict(
                3 => ExprNode(3, 2, 1.0),
                8 => ExprNode(8, 2, 3.0),
                9 => ExprNode(9, 7, 4.0),
                10 => ExprNode(10, 6, 5.0),
            )
        )

        @test expected == new_geno
    end
end
