using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary
# include("util.jl")

@testset "NumbersGame" begin
@testset "Individual" begin
    rng = StableRNG(42)
    # genome initialization with default value 0
    indiv = VectorIndiv("A", 1, collect(1:5), fill(false, 5))
    @test typeof(indiv) == VectorIndiv{ScalarGene{Bool}}
    @test indiv.iid == 1
    @test [g.gid for g in indiv.genes] == collect(1:5)
    @test [g.iid for g in indiv.genes] == fill(1, 5)
    @test [g.val for g in indiv.genes] == fill(false, 5)
    @test [g.gen for g in indiv.genes] == fill(1, 5)
    @test genotype(indiv).genes == fill(false, 5)

    # genome initialization with default value 1
    indiv = VectorIndiv("A", 2, collect(6:10), fill(true, 5))
    @test typeof(indiv) == VectorIndiv{ScalarGene{Bool}}
    @test indiv.iid == 2
    @test [g.gid for g in indiv.genes] == collect(6:10)
    @test [g.iid for g in indiv.genes] == fill(2, 5)
    @test [g.val for g in indiv.genes] == fill(true, 5)
    @test [g.gen for g in indiv.genes] == fill(1, 5)
    @test genotype(indiv).genes == fill(true, 5)

end

 @testset "VectorIndivConfig" begin
    # genome initialization with random values
    rng = StableRNG(42)
    sc = SpawnCounter()

    icfg = VectorIndivConfig(
        spkey = "A",
        sc = sc,
        rng = rng,
        dtype = Bool,
        width = 100
    )
    indivs = sort(collect(icfg(10, false)), by = i -> i.iid)

    indiv = indivs[1]
    @test length(indiv.genes) == 100
    @test sum(genotype(indiv).genes) == 0

    indiv = indivs[10]
    @test indiv.iid == 10
    @test indiv.genes[1].gid == 901
    @test indiv.genes[100].gid == 1000
    @test sum(genotype(indiv).genes) == 0

    indivs = sort(collect(icfg(10, true)), by = i -> i.iid)
    indiv = indivs[1]
    @test sum(genotype(indiv).genes) == 100

    indivs = icfg(5)
    for indiv in indivs
        @test sum(genotype(indiv).genes) != 0
        @test sum(genotype(indiv).genes) != 100
    end

end


@testset "Spawner" begin
    rng = StableRNG(42)
    sc = SpawnCounter()

    spawner = Spawner(
        spkey = "A",
        n_pop = 10,
        icfg = VectorIndivConfig(
            spkey = "A",
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = 10
        ),
        replacer = IdentityReplacer(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(sc = sc),
        mutators = Mutator[]
    )

    species = spawner(false)
    indivs = sort(collect(species.pop), by = i -> i.iid)
    @test length(indivs) == 10
    @test all(["A" == indivs[i].spkey for i in 1:10])
    @test sum([sum(genotype(indiv).genes) for indiv in values(indivs)]) == 0

    vets = dummyvets(species)

    species = spawner(2, vets)
    @test length(species.children) == 10
    @test sort(collect([indiv.iid for indiv in species.children])) == collect(11:20)
end

@testset "AllvsAllOrder" begin
    rng = StableRNG(42)

    spkey = "A"
    sc = SpawnCounter()
    spawnerA = Spawner(
        spkey = spkey,
        n_pop = 10,
        icfg = VectorIndivConfig(
            spkey = spkey,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = 10
        ),
        replacer = TruncationReplacer(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(sc = sc),
        mutators = Mutator[]
    )

    spkey = "B"
    sc = SpawnCounter()
    spawnerB = Spawner(
        spkey = spkey,
        n_pop = 10,
        icfg = VectorIndivConfig(
            spkey = spkey,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = 10
        ),
        replacer = TruncationReplacer(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(sc = sc),
        mutators = Mutator[]
    )
    speciesA = Species("A", spawnerA.icfg(5, false), spawnerA.icfg(5, true))
    speciesB = Species("B", spawnerB.icfg(5, false), spawnerB.icfg(5, true))
    allsp = Set([speciesA, speciesB])

    order = AllvsAllOrder(
        domain = NGGradient(),
        obscfg = NGObsConfig(),
        phenocfgs = Dict(
            "A" => SumPhenoConfig(role = :A),
            "B" => SumPhenoConfig(role = :B),
        ),
    )
    recipes = order(speciesA, speciesB)
    @test length(recipes) == 100
    jobcfg = SerialJobConfig()
    job = jobcfg(Set([order]), allsp)
    outcomes = perform(job)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    println("done")
    @test all([fitness(vet) == 0 for vet in allvets["A"].pop])

    # recipe_set = Set{Set{Recipe}}(order, pops, 5)
    # @test all([length(recipes) == 10 for recipes in recipe_set])
end

# @testset "SamplerOrder/Recipes2" begin
#     rng = StableRNG(123)
#     popA = GenoPopConfig(key="A", n_genos=10,
#                          geno_cfg=DefaultBitstringConfig(width=10, default_val=true))()
#     popB = GenoPopConfig(key="B", n_genos=10,
#                          geno_cfg=DefaultBitstringConfig(width=10, default_val=false))()
#     pops = Set([popA, popB])
#     order = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(role = :subject, phenocfg = IntPhenoConfig()),
#             "B" => PopRole(role = :test, phenocfg = IntPhenoConfig())
#         ),
#         subjects_key = "A",
#         tests_key = "B",
#         n_samples = 1,
#         rng = rng)
#     recipes = (order)(pops)
#     @test length(recipes) == 10
#     recipe_set = Set{Set{Recipe}}(order, pops, 5)
#     @test all([length(recipes) == 2 for recipes in recipe_set])
# end

# @testset "AllvsAllOrder" begin
#     rng = StableRNG(123)
#     popA = GenoPopConfig(key="A", n_genos=10,
#                             geno_cfg=DefaultBitstringConfig(width=10, default_val=true))()
#     popB = GenoPopConfig(key="B", n_genos=10,
#                             geno_cfg=DefaultBitstringConfig(width=10, default_val=false))()
#     pops = Set([popA, popB])
#     pheno_cfg = IntPhenoConfig()
#     order = AllvsAllMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(role = :subject, phenocfg = IntPhenoConfig()),
#             "B" => PopRole(role = :test, phenocfg = IntPhenoConfig()),))
#     recipes = (order)(pops)
#     @test length(recipes) == 100
# end



# @testset "ParallelJob" begin
#     rng = StableRNG(123)
#     geno_cfg = DefaultBitstringConfig(width=100, default_val=true)
#     popA = GenoPopConfig(key="A", n_genos=10, geno_cfg=geno_cfg)()
#     geno_cfg = DefaultBitstringConfig(width=100, default_val=false)
#     popB = GenoPopConfig(key="B", n_genos=10, geno_cfg=geno_cfg)()
#     pops = Set([popA, popB])
#     pheno_cfg = IntPhenoConfig()
#     orderA = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(role = :subject, phenocfg = IntPhenoConfig()),
#             "B" => PopRole(role = :test, phenocfg = IntPhenoConfig())
#         ),
#         subjects_key = "A",
#         tests_key = "B",
#         n_samples = 5,
#         rng = rng)
#     orderB = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "B" => PopRole(role = :subject, phenocfg = IntPhenoConfig()),
#             "A" => PopRole(role = :test, phenocfg = IntPhenoConfig()),
#         ),
#         subjects_key = "B",
#         tests_key = "A",
#         n_samples = 5,
#         rng = rng)
#     orders = Set([orderA, orderB])
#     cfg = ParallelJobsConfig(n_jobs=5)
#     jobs = cfg(orders, pops)
#     @test all([length(job.recipes) == 20 for job in jobs])
#     flag = true
#     for job in jobs
#         for recipe in job.recipes
#             for key in Set{String}(recipe)
#                 if key ∉ keys(job.genodict)
#                     flag = false
#                 end
#             end
#         end
#     end
#     @test flag
# end

# @testset "Phenotypes" begin
#     geno = DefaultBitstringConfig(width=100, default_val=true)("test")

#     pheno_cfg = IntPhenoConfig()
#     pheno = pheno_cfg(geno)
#     @test typeof(pheno) == IntPheno
#     @test pheno.traits == 100

#     pheno_cfg = VectorPhenoConfig(subvector_width=10)
#     pheno = pheno_cfg(geno)
#     @test length(pheno.traits) == 10
#     @test sum([sum(subv) for subv in pheno.traits]) == 100
# end

# @testset "Mixes" begin
#     rng = StableRNG(123)
#     geno_cfg = DefaultBitstringConfig(width=10, default_val=true)
#     popA = GenoPopConfig(key="A", n_genos=10, geno_cfg=geno_cfg)()
#     geno_cfg = DefaultBitstringConfig(width=10, default_val=false)
#     popB = GenoPopConfig(key="B", n_genos=10, geno_cfg=geno_cfg)()
#     pops = Set([popA, popB])
#     orderA = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(role = :subject, phenocfg = IntPhenoConfig()),
#             "B" => PopRole(role = :test, phenocfg = IntPhenoConfig())
#         ),
#         subjects_key = "A",
#         tests_key = "B",
#         n_samples = 5,
#         rng = rng)
#     cfg = SerialJobConfig()
#     job = cfg(Set([orderA]), pops)
#     mixes = Set{Mix}(job)
#     @test length(job.recipes) == length(mixes)
# end

# @testset "Outcomes: Int Pheno" begin
#     rng = StableRNG(123)
#     geno_cfg = DefaultBitstringConfig(width=10, default_val=true)
#     popA = GenoPopConfig(key="A", n_genos=10, geno_cfg=geno_cfg)()
#     geno_cfg = DefaultBitstringConfig(width=10, default_val=false)
#     popB = GenoPopConfig(key="B", n_genos=10, geno_cfg=geno_cfg)()
#     pops = Set([popA, popB])
#     domain = NGGradient()
#     pheno_cfg = IntPhenoConfig()
#     orderA = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(role = :subject, phenocfg = IntPhenoConfig()),
#             "B" => PopRole(role = :test, phenocfg = IntPhenoConfig())
#         ),
#         subjects_key = "A",
#         tests_key = "B",
#         n_samples = 5,
#         rng = rng)
#     orderB = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "B" => PopRole(role = :subject, phenocfg = IntPhenoConfig()),
#             "A" => PopRole(role = :test, phenocfg = IntPhenoConfig()),
#         ),
#         subjects_key = "B",
#         tests_key = "A",
#         n_samples = 5,
#         rng = rng)
#     orders = Set([orderA, orderB])
#     cfg = SerialJobConfig()
#     job = cfg(orders, pops)
#     outcomes = Set{Outcome}(job)
#     @test length(outcomes) == 100
#     flag = true
#     for outcome in outcomes
#         for result in outcome.results
#             if occursin("A", result.key) &&
#                     result.role == :subject &&
#                     result.score == 0
#                 flag = false
#             end
#             if occursin("B", result.key) &&
#                     result.role == :subject &&
#                     result.score == 1
#                 flag = false
#             end
#         end
#     end
#     @test flag
# end

# @testset "Outcomes: Vector Pheno" begin
#     rng = StableRNG(123)
#     geno_cfg = DefaultBitstringConfig(width=10, default_val=true)
#     popA = GenoPopConfig(key="A", n_genos=10, geno_cfg=geno_cfg)()
#     geno_cfg = DefaultBitstringConfig(width=10, default_val=false)
#     popB = GenoPopConfig(key="B", n_genos=10, geno_cfg=geno_cfg)()
#     pops = Set([popA, popB])
#     domain = NGGradient()
#     pheno_cfg = VectorPhenoConfig(subvector_width=10)
#     orderA = SamplerMixOrder(
#         domain = NGFocusing(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(
#                 role = :subject,
#                 phenocfg = VectorPhenoConfig(subvector_width=10)),
#             "B" => PopRole(
#                 role = :test,
#                 phenocfg = VectorPhenoConfig(subvector_width=10)),
#         ),
#         subjects_key = "A",
#         tests_key = "B",
#         n_samples = 5,
#         rng = rng)
#     orderB = SamplerMixOrder(
#         domain = NGFocusing(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "B" => PopRole(
#                 role = :subject,
#                 phenocfg = VectorPhenoConfig(subvector_width=10)),
#             "A" => PopRole(
#                 role = :test,
#                 phenocfg = VectorPhenoConfig(subvector_width=10)),
#         ),
#         subjects_key = "B",
#         tests_key = "A",
#         n_samples = 5,
#         rng = rng)
#     orders = Set([orderA, orderB])
#     cfg = SerialJobConfig()
#     job = cfg(orders, pops)
#     outcomes = Set{Outcome}(job)
#     @test length(outcomes) == 100
#     flag = true
#     for outcome in outcomes
#         for result in outcome.results
#             if occursin("A", result.key) &&
#                     result.role == :subject &&
#                     result.score == 0
#                 flag = false
#             end
#             if occursin("B", result.key) &&
#                     result.role == :subject &&
#                     result.score == 1
#                 flag = false
#             end
#         end
#     end
#     @test flag
# end

# @testset "NGGradient" begin
#     domain = NGGradient()
#     a = IntPheno("a", 4)
#     b = IntPheno("b", 5)
#     rolephenos = Dict(:subject => a, :test => b)
#     mix = SetMix(1, domain, ScalarOutcome, rolephenos)
#     o = (mix)()
#     @test getscore("a", o) == false

#     Sₐ = Set([IntPheno(string(x), x) for x in 1:3])
#     Sᵦ = Set([IntPheno(string(x), x) for x in 6:8])
    
#     fitness_a = 0
#     for other ∈ Sₐ
#         rolephenos = Dict(:subject => a, :test => other)
#         mix = SetMix(1, domain, ScalarOutcome, rolephenos)
#         #mix = PairMix(1, domain, TestPairOutcome, a, other)
#         o = (mix)()
#         fitness_a += getscore("a", o)
#     end

#     @test fitness_a == 3

#     fitness_b = 0
#     for other ∈ Sᵦ
#         rolephenos = Dict(:subject => b, :test => other)
#         mix = SetMix(1, domain, ScalarOutcome, rolephenos)
#         #mix = PairMix(1, domain, TestPairOutcome, b, other)
#         o = (mix)()
#         fitness_b += getscore(:subject, o)
#     end

#     @test fitness_b == 0
# end

# @testset "NGFocusing" begin
#     domain = NGFocusing()

#     a = VectorPheno("a", [4, 16])
#     b = VectorPheno("b", [5, 14])

#     rolephenos = Dict(:subject => a, :test => b)
#     mix = SetMix(1, domain, ScalarOutcome, rolephenos)
#     #mix = PairMix(1, domain, TestPairOutcome, a, b)
#     o = (mix)()
#     @test getscore(:subject, o) == true

#     a = VectorPheno("a", [4, 16])
#     b = VectorPheno("b", [5, 16])
#     rolephenos = Dict(:subject => a, :test => b)
#     mix = SetMix(1, domain, ScalarOutcome, rolephenos)
#     #mix = PairMix(1, domain, TestPairOutcome, a, b)
#     o = (mix)()
#     @test getscore(:subject, o) == false

#     a = VectorPheno("a", [5, 16, 8])
#     b = VectorPheno("b", [4, 16, 6])
#     rolephenos = Dict(:subject => a, :test => b)
#     mix = SetMix(1, domain, ScalarOutcome, rolephenos)
#     o = (mix)()
#     @test getscore(:subject, o) == true
# end

# @testset "NGRelativism" begin
#     domain = NGRelativism()

#     a = VectorPheno("a", [1, 6])
#     b = VectorPheno("b", [4, 5])
#     c = VectorPheno("c", [2, 4])

#     mix = SetMix(1, domain, ScalarOutcome, Dict(:subject => a, :test => b))
#     o = (mix)()
#     @test getscore(:subject, o) == true

#     mix = SetMix(1, domain, ScalarOutcome, Dict(:subject => b, :test => c))
#     o = (mix)()
#     @test getscore(:subject, o) == true

#     mix = SetMix(1, domain, ScalarOutcome, Dict(:subject => c, :test => a))
#     o = (mix)()
#     @test getscore(:subject, o) == true
# end

# @testset "Roulette/Reproduce/Elitism" begin
#     rng = StableRNG(123)
#     winners = Set([BitstringGeno(string("A-", x), ones(Bool, 10), Set{String}()) for x in 1:5])
#     losers = Set([BitstringGeno(string("A-", x), zeros(Bool, 10), Set{String}()) for x in 6:10])
#     popA = GenoPop("A", 11, union(winners, losers))
#     geno_cfg = DefaultBitstringConfig(width=10, default_val=false)
#     popB = GenoPopConfig(key="B", n_genos=10, geno_cfg=geno_cfg)()
#     pops = Set([popA, popB])
#     orderA = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(
#                 role = :subject,
#                 phenocfg = IntPhenoConfig()),
#             "B" => PopRole(
#                 role = :test,
#                 phenocfg = IntPhenoConfig()),
#         ),
#         subjects_key = "A",
#         tests_key = "B",
#         n_samples = 5,
#         rng = rng)
#     # orderA = SamplerOrder(domain=domain, outcome=TestPairOutcome, subjects_key="A", subjects_cfg=pheno_cfg,
#     #                       tests_key="B", tests_cfg=pheno_cfg, n_samples=5, rng=rng)
#     orders = Set([orderA])
#     cfg = SerialJobConfig()
#     job = cfg(orders, pops)
#     outcomes = Set{Outcome}(job)
#     selector = RouletteSelector(rng=rng, n_elite=5, n_singles=5, n_couples=0)
#     selections = (selector)(popA, outcomes)
#     @test Set(selections.elites) == winners
#     reproducer = BitstringReproducer(rng, 0.05)
#     newpop = (reproducer)(GenoPop, popA, outcomes, selections)
#     @test length(newpop.genos) == 10
#     flag = true
#     genokeys = keys(Dict{String, Genotype}(newpop))
#     for s in [string("A-", x) for x in 1:5]
#         if s ∉ genokeys
#             flag = false
#         end
#     end
#     for s in [string("A-", x) for x in 11:15]
#         if s ∉ genokeys
#             flag = false
#         end
#     end
#     @test flag
# end

# @testset "Coev" begin
#     # RNG #
#     coev_key = "NG: Control"
#     trial = 1
#     rng = StableRNG(123)

#     ## Populations ##
#     width = 100
#     n_genos = 25
#     popA = GenoPopConfig(
#         key="A", n_genos=n_genos,
#         geno_cfg=DefaultBitstringConfig(width=width, default_val=true))()
#     popB = GenoPopConfig(
#         key="B", n_genos=n_genos,
#         geno_cfg=DefaultBitstringConfig(width=width, default_val=false))()
#     pops = Set([popA, popB])

#     ## Job ##
#     job_cfg = SerialJobConfig()

#     orderA = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(
#                 role = :subject,
#                 phenocfg = IntPhenoConfig()),
#             "B" => PopRole(
#                 role = :test,
#                 phenocfg = IntPhenoConfig()),
#         ),
#         subjects_key = "A",
#         tests_key = "B",
#         n_samples = 15,
#         rng = rng)
#     orderB = SamplerMixOrder(
#         domain = NGGradient(),
#         outcome = ScalarOutcome,
#         poproles = Dict(
#             "A" => PopRole(
#                 role = :test,
#                 phenocfg = IntPhenoConfig()),
#             "B" => PopRole(
#                 role = :subject,
#                 phenocfg = IntPhenoConfig()),
#         ),
#         subjects_key = "B",
#         tests_key = "A",
#         n_samples = 15,
#         rng = rng)
#     orders = Set([orderA, orderB])

#     ## Spawners ##
#     mutrate = 0.05
#     selectorA = RouletteSelector(rng=rng, n_elite=0, n_singles=n_genos, n_couples=0)
#     reproducerA = BitstringReproducer(rng=rng, mutrate=mutrate)
#     spawnerA = Spawner("A", selectorA, reproducerA, GenoPop)
#     selectorB = RouletteSelector(rng=rng, n_elite=0, n_singles=n_genos, n_couples=0)
#     reproducerB = BitstringReproducer(rng=rng, mutrate=mutrate)
#     spawnerB = Spawner("B", selectorB, reproducerB, GenoPop)
#     spawners = Set([spawnerA, spawnerB])

#     ## Loggers ##
#     loggers = Set([BasicGeneLogger("A"), FitnessLogger("A"),
#                    BasicGeneLogger("B"), FitnessLogger("B")])
#     coev_cfg = CoevConfig(;
#         key=coev_key,
#         trial=trial,
#         job_cfg=job_cfg,
#         orders=orders, 
#         spawners=spawners,
#         loggers=loggers,)
#     gen = 1
#     while gen < 200
#         gen += 1
#         pops = coev_cfg(gen, pops)
#     end
# end



end