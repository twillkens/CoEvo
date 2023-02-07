using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary
# include("util.jl")

function testspawner(rng::AbstractRNG, spkey::String; n_pop = 10, width = 10)
    sc = SpawnCounter()
    Spawner(
        spkey = spkey,
        n_pop = n_pop,
        icfg = VectorIndivConfig(
            spkey = spkey,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = width
        ),
        replacer = TruncationReplacer(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(sc = sc),
        mutators = Mutator[]
    )
end

function testorder()
    AllvsAllOrder(
        domain = NGGradient(),
        obscfg = NGObsConfig(),
        phenocfgs = Dict(
            "A" => SumPhenoConfig(role = :A),
            "B" => SumPhenoConfig(role = :B),
        ),
    )
end

function vecorder()
    AllvsAllOrder(
        domain = NGFocusing(),
        obscfg = NGObsConfig(),
        phenocfgs = Dict(
            "A" => SubvecPhenoConfig(role = :A, subvec_width = 10),
            "B" => SubvecPhenoConfig(role = :B, subvec_width = 10),
        ),
    )
end

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
    spawner = testspawner(rng, "A")
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

@testset "AllvsAllOrder/SerialConfig" begin
    rng = StableRNG(42)

    spkey = "A"
    sc = SpawnCounter()
    spawnerA = testspawner(rng, "A")
    spawnerB = testspawner(rng, "B")

    speciesA = Species("A", spawnerA.icfg(5, false), spawnerA.icfg(5, true))
    speciesB = Species("B", spawnerB.icfg(5, false), spawnerB.icfg(5, true))
    allsp = Set([speciesA, speciesB])
    spawners = Set([spawnerA, spawnerB])

    order = testorder()
    recipes = order(speciesA, speciesB)
    @test length(recipes) == 100
    jobcfg = SerialJobConfig()
    job = jobcfg(allsp, recipes)
    outcomes = perform(job)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    @test all(fitness(vet) == 5 for vet in allvets["A"].children)
    @test all(fitness(vet) == 0 for vet in allvets["B"].pop)
    @test all(fitness(vet) == 5 for vet in allvets["B"].children)

    newsp = spawnerA(2, allvets["A"])
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))

    newsp = spawnerB(2, allvets["B"])
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))
end


@testset "AllvsAllOrder/ParallelJobConfig" begin
    rng = StableRNG(42)

    spawnerA = testspawner(rng, "A")
    spawnerB = testspawner(rng, "B")
    speciesA = Species("A", spawnerA.icfg(5, false), spawnerA.icfg(5, true))
    speciesB = Species("B", spawnerB.icfg(5, false), spawnerB.icfg(5, true))
    allsp = Set([speciesA, speciesB])
    spawners = Set([spawnerA, spawnerB])
    order = testorder()
    recipes = order(allsp)
    @test length(recipes) == 100

    jobcfg = ParallelJobConfig(n_jobs = 5)
    jobs = jobcfg(allsp, recipes)
    @test length(jobs) == 5
    @test all(length(job.recipes) == 20 for job in jobs)
    outcomes = union([perform(job) for job in jobs]...)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    @test all(fitness(vet) == 5 for vet in allvets["A"].children)
    @test all(fitness(vet) == 0 for vet in allvets["B"].pop)
    @test all(fitness(vet) == 5 for vet in allvets["B"].children)

    newsp = spawnerA(2, allvets["A"])
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))

    newsp = spawnerB(2, allvets["B"])
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))
end


@testset "Outcomes: Vector Pheno" begin
    rng = StableRNG(123)

    spawnerA = testspawner(rng, "A"; n_pop = 10, width = 100)
    spawnerB = testspawner(rng, "B"; n_pop = 10, width = 100)
    speciesA = Species("A", spawnerA.icfg(10, true))
    speciesB = Species("B", spawnerB.icfg(10, false))
    allsp = Set([speciesA, speciesB])
    spawners = Set([spawnerA, spawnerB])
    order = vecorder()
    recipes = order(allsp)
    @test length(recipes) == 100

    jobcfg = SerialJobConfig()
    work = jobcfg(allsp, recipes)
    outcomes = perform(work)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    @test sum(fitness(vet) for vet in allindivs(allvets["A"])) == 100
    @test sum(fitness(vet) for vet in allindivs(allvets["B"])) == 0
end

@testset "NGGradient" begin
    domain = NGGradient()
    obscfg = NGObsConfig()
    phenoA = ScalarPheno("A", 1, 4)
    phenoB = ScalarPheno("B", 1, 5) 
    phenos = Dict(
        :A => phenoA,
        :B => phenoB
    )
    mix = Mix(1, domain, obscfg, phenos)
    o = stir(mix)
    @test getscore("A", 1, o) == false
    @test getscore("B", 1, o) == true

    Sₐ = Set(ScalarPheno("C", i, x) for (i, x) in enumerate(1:3))
    Sᵦ = Set(ScalarPheno("D", i, x) for (i, x) in enumerate(6:8))
    
    fitnessA = 0
    for other ∈ Sₐ
        phenos = Dict(:A => phenoA, :B => other)
        mix = Mix(2, domain, obscfg, phenos)
        o = stir(mix)
        fitnessA += getscore("A", 1, o)
    end

    @test fitnessA == 3

    fitnessB = 0
    for other ∈ Sᵦ
        phenos = Dict(:A => phenoB, :B => other)
        mix = Mix(3, domain, obscfg, phenos)
        o = stir(mix)
        fitnessB += getscore("B", 1, o)
    end

    @test fitnessB == 0
end

@testset "NGFocusing" begin
    domain = NGFocusing()
    obscfg = NGObsConfig()

    phenoA = VectorPheno("A", 1, [4, 16])
    phenoB = VectorPheno("B", 1, [5, 14])
    phenos = Dict(:A => phenoA, :B => phenoB)
    mix = Mix(1, domain, obscfg, phenos)
    o = stir(mix)
    @test getscore("A", 1, o) == true

    phenoB = VectorPheno("B", 1, [5, 16])
    phenos = Dict(:A => phenoA, :B => phenoB)
    mix = Mix(1, domain, obscfg, phenos)
    o = stir(mix)
    @test getscore("A", 1, o) == false

    phenoA = VectorPheno("A", 1, [5, 16, 8])
    phenoB = VectorPheno("B", 1, [4, 16, 6])
    phenos = Dict(:A => phenoA, :B => phenoB)
    mix = Mix(1, domain, obscfg, phenos)
    o = stir(mix)
    @test getscore("A", 1, o) == true

end

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