using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary
# include("util.jl")

function testspawner(rng::AbstractRNG, spid::Symbol; n_pop = 10, width = 10)
    sc = SpawnCounter()
    Spawner(
        spid = spid,
        n_pop = n_pop,
        icfg = VectorIndivConfig(
            spid = spid,
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

function roulettespawner(rng::AbstractRNG, spid::Symbol; n_pop = 50, width = 100)
    sc = SpawnCounter()
    Spawner(
        spid = spid,
        n_pop = n_pop,
        icfg = VectorIndivConfig(
            spid = spid,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = width
        ),
        replacer = GenerationalReplacer(n_elite = 10),
        selector =  RouletteSelector(rng = rng, μ = n_pop),
        recombiner = CloneRecombiner(sc = sc),
        mutators = [BitflipMutator(rng = rng, sc = sc, mutrate = 0.05)]
    )
end

function testorder()
    AllvsAllOrder(
        oid = :NG,
        domain = NGGradient(),
        obscfg = NGObsConfig(),
        phenocfgs = Dict(
            :A => SumPhenoConfig(role = :A),
            :B => SumPhenoConfig(role = :B),
        ),
    )
end

function vecorder()
    AllvsAllOrder(
        oid = :NG,
        domain = NGFocusing(),
        obscfg = NGObsConfig(),
        phenocfgs = Dict(
            :A => SubvecPhenoConfig(role = :A, subvec_width = 10),
            :B => SubvecPhenoConfig(role = :B, subvec_width = 10),
        ),
    )
end

@testset "NumbersGame" begin
@testset "Individual" begin
    rng = StableRNG(42)
    # genome initialization with default value 0
    indiv = VectorIndiv(:A, UInt32(1), collect(UInt32, 1:5), fill(false, 5))
    @test typeof(indiv) == VectorIndiv{ScalarGene{Bool}}
    @test indiv.iid == 1
    @test [g.gid for g in indiv.genes] == collect(UInt32, 1:5)
    @test [g.val for g in indiv.genes] == fill(false, 5)
    @test genotype(indiv).genes == fill(false, 5)

    # genome initialization with default value 1
    indiv = VectorIndiv(:A, UInt32(2), collect(UInt32, 6:10), fill(true, 5))
    @test typeof(indiv) == VectorIndiv{ScalarGene{Bool}}
    @test indiv.iid == 2
    @test [g.gid for g in indiv.genes] == collect(UInt32, 6:10)
    @test [g.val for g in indiv.genes] == fill(true, 5)
    @test genotype(indiv).genes == fill(true, 5)

end

 @testset "VectorIndivConfig" begin
    # genome initialization with random values
    rng = StableRNG(42)
    sc = SpawnCounter()

    icfg = VectorIndivConfig(
        spid = :A,
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

@testset "NGGradient" begin
    domain = NGGradient()
    obscfg = NGObsConfig()
    phenoA = ScalarPheno(:A, 1, 4)
    phenoB = ScalarPheno(:B, 1, 5) 
    phenos = Dict(
        :A => phenoA,
        :B => phenoB
    )

    recipe = Recipe(:NG, Set([phenoA.ikey, phenoB.ikey]))
    mix = Mix(recipe, domain, obscfg, phenos)
    o = stir(mix)
    @test getscore(:A, 1, o) == false
    @test getscore(:B, 1, o) == true

    Sₐ = Set(ScalarPheno(:C, (i), x) for (i, x) in enumerate(1:3))
    Sᵦ = Set(ScalarPheno(:D, (i), x) for (i, x) in enumerate(6:8))
    
    fitnessA = 0
    for other ∈ Sₐ
        phenos = Dict(:A => phenoA, :B => other)
        mix = Mix(domain, obscfg, phenos)
        o = stir(mix)
        fitnessA += getscore(:A, 1, o)
    end

    @test fitnessA == 3

    fitnessB = 0
    for other ∈ Sᵦ
        phenos = Dict(:A => phenoB, :B => other)
        mix = Mix(domain, obscfg, phenos)
        o = stir(mix)
        fitnessB += getscore(:B, 1, o)
    end

    @test fitnessB == 0
end

@testset "NGFocusing" begin
    domain = NGFocusing()
    obscfg = NGObsConfig()

    phenoA = VectorPheno(:A, UInt32(1), [4, 16])
    phenoB = VectorPheno(:B, UInt32(1), [5, 14])
    phenos = Dict(:A => phenoA, :B => phenoB)
    mix = Mix(domain, obscfg, phenos)
    o = stir(mix)
    @test getscore(:A, UInt32(1), o) == true

    phenoB = VectorPheno(:B, UInt32(1), [5, 16])
    phenos = Dict(:A => phenoA, :B => phenoB)
    mix = Mix(domain, obscfg, phenos)
    o = stir(mix)
    @test getscore(:A, UInt32(1), o) == false

    phenoA = VectorPheno(:A, UInt32(1), [5, 16, 8])
    phenoB = VectorPheno(:B, UInt32(1), [4, 16, 6])
    phenos = Dict(:A => phenoA, :B => phenoB)
    mix = Mix(domain, obscfg, phenos)
    o = stir(mix)
    @test getscore(:A, UInt32(1), o) == true

end

@testset "NGRelativism" begin
    domain = NGRelativism()
    obscfg = NGObsConfig()

    a = VectorPheno(:A, UInt32(1), [1, 6])
    b = VectorPheno(:B, UInt32(1), [4, 5])
    c = VectorPheno(:C, UInt32(1), [2, 4])

    o = stir(Mix(domain, obscfg, Dict(:A => a, :B => b)))
    @test getscore(:A, UInt32(1), o) == true

    o = stir(Mix(domain, obscfg, Dict(:A => b, :B => c)))
    @test getscore(:B, UInt32(1), o) == true

    o = stir(Mix(domain, obscfg, Dict(:A => c, :B => a)))
    @test getscore(:C, UInt32(1), o) == true
end

@testset "Spawner" begin
    rng = StableRNG(42)
    sc = SpawnCounter()
    spawner = testspawner(rng, :A)
    species = spawner(false)
    indivs = sort(collect(species.pop), by = i -> i.iid)
    @test length(indivs) == 10
    @test all([:A == indivs[i].spid for i in 1:10])
    @test sum([sum(genotype(indiv).genes) for indiv in values(indivs)]) == 0

    vets = dummyvets(species)

    species = spawner(UInt16(2), vets)
    @test length(species.children) == 10
    @test sort(collect([indiv.iid for indiv in species.children])) == collect(11:20)
end

@testset "AllvsAllOrder/SerialConfig" begin
    rng = StableRNG(42)

    spid = :A
    sc = SpawnCounter()
    spawnerA = testspawner(rng, :A)
    spawnerB = testspawner(rng, :B)

    speciesA = Species(:A, spawnerA.icfg(5, false), spawnerA.icfg(5, true))
    speciesB = Species(:B, spawnerB.icfg(5, false), spawnerB.icfg(5, true))
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
    vetdict = Dict(sp.spid => sp for sp in allvets)
    @test all(fitness(vet) == 5 for vet in vetdict[:A].children)
    @test all(fitness(vet) == 0 for vet in vetdict[:B].pop)
    @test all(fitness(vet) == 5 for vet in vetdict[:B].children)

    newsp = spawnerA(UInt16(2), allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))

    newsp = spawnerB(UInt16(2), allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))
end


@testset "AllvsAllOrder/ParallelJobConfig" begin
    rng = StableRNG(42)

    spawnerA = testspawner(rng, :A)
    spawnerB = testspawner(rng, :B)
    speciesA = Species(:A, spawnerA.icfg(5, false), spawnerA.icfg(5, true))
    speciesB = Species(:B, spawnerB.icfg(5, false), spawnerB.icfg(5, true))
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
    vetdict = Dict(sp.spid => sp for sp in allvets)
    @test all(fitness(vet) == 5 for vet in vetdict[:A].children)
    @test all(fitness(vet) == 0 for vet in vetdict[:B].pop)
    @test all(fitness(vet) == 5 for vet in vetdict[:B].children)

    newsp = spawnerA(UInt16(2), allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))

    newsp = spawnerB(UInt16(2), allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(iid for iid in newsp.parents) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))
end


@testset "Outcomes: Vector Pheno" begin
    rng = StableRNG(123)

    spawnerA = testspawner(rng, :A; n_pop = 10, width = 100)
    spawnerB = testspawner(rng, :B; n_pop = 10, width = 100)
    speciesA = Species(:A, spawnerA.icfg(10, true))
    speciesB = Species(:B, spawnerB.icfg(10, false))
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
    @test sum(fitness(vet) for vet in allindivs(allvets, :A)) == 100
    @test sum(fitness(vet) for vet in allindivs(allvets, :B)) == 0
end


@testset "Generational/Roulette/Bitflip" begin
    rng = StableRNG(42)
    spawnerA = roulettespawner(rng, :A, n_pop = 50, width = 100)
    spawnerB = roulettespawner(rng, :B, n_pop = 50, width = 100)
    spawners = Set([spawnerA, spawnerB])
    order = testorder()
    speciesA = spawnerA(false)
    speciesB = spawnerB(false)
    
    allsp = Set([speciesA, speciesB])
    recipes = order(allsp)
    @test length(recipes) == 2500
    jobcfg = SerialJobConfig()
    work = jobcfg(allsp, recipes)
    outcomes = perform(work)
    allvets = makevets(allsp, outcomes)
    newspA = spawnerA(UInt16(2), allvets)
    newspB = spawnerB(UInt16(2), allvets)

    allsp = Set([newspA, newspB])
    recipes = order(allsp)
    @test length(recipes) == 10000
    work = jobcfg(allsp, recipes)
    outcomes = perform(work)
    allvets = makevets(allsp, outcomes)
    newspA = spawnerA(UInt16(3), allvets)
    newspB = spawnerB(UInt16(3), allvets)
    @test length(newspA.pop) == 50
    @test length(newspA.children) == 50
end

@testset "Coev" begin
    # RNG #
    coev_key = "NG: Gradient"
    trial = 1
    seed = UInt64(42)
    rng = StableRNG(seed)

    coev_cfg = CoevConfig(;
        key = "Coev Test",
        trial = 1,
        seed = seed,
        rng = rng,
        jobcfg = SerialJobConfig(),
        orders = Set([testorder()]), 
        spawners = Set([
            testspawner(rng, :A, n_pop = 50, width = 100),
            testspawner(rng, :B, n_pop = 50, width = 100),
        ]),
        loggers = Set(Logger[]))
    gen = UInt16(1)
    allsp = coev_cfg()
    while gen < 200
        println(gen)
        allsp = coev_cfg(gen, allsp)
        gen += UInt16(1)
    end
end



end