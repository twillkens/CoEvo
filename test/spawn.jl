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

function dummyikey()
    IndivKey(:spdummy, 1)
end

function dummytkey()
    TestKey(:odummy, Set([dummyikey()]))
end

function dummyvets(indivs::Set{<:Individual})
    Set(Veteran(indiv.ikey, indiv, Dict(dummytkey() => 1)) for indiv in indivs)
end

function dummyvets(sp::Species)
    Species(sp.spid, dummyvets(sp.pop), dummyvets(sp.children))
end

@testset "NumbersGame" begin
@testset "Individual" begin
    rng = StableRNG(42)
    # genome initialization with default value 0
    gids = collect(UInt32, 1:5)
    vals = fill(false, 5)
    indiv = VectorIndiv(:A, 1, gids, vals)
    @test typeof(indiv) == VectorIndiv{ScalarGene{Bool}}
    @test indiv.iid == 1
    @test indiv.gids == gids
    @test indiv.vals == vals
    @test genotype(indiv).genes == vals

    # genome initialization with default value 1
    gids = collect(UInt32, 6:10)
    vals = fill(true, 5)
    indiv = VectorIndiv(:A, 2, gids, vals)
    @test typeof(indiv) == VectorIndiv{ScalarGene{Bool}}
    @test indiv.iid == 2
    @test indiv.gids == gids
    @test indiv.vals == vals
    @test genotype(indiv).genes == vals

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
    roledict = Dict(
        :A => phenoA,
        :B => phenoB
    )
    mix = Mix(:NG, domain, obscfg, roledict)
    o = stir(mix)
    @test getscore(:A, 1, o) == false
    @test getscore(:B, 1, o) == true

    Sₐ = Set(ScalarPheno(:C, i, x) for (i, x) in enumerate(1:3))
    Sᵦ = Set(ScalarPheno(:D, i, x) for (i, x) in enumerate(6:8))
    
    fitnessA = 0
    for other ∈ Sₐ
        roledict = Dict(:A => phenoA, :B => other)
        mix = Mix(:NG, domain, obscfg, roledict)
        o = stir(mix)
        fitnessA += getscore(:A, 1, o)
    end

    @test fitnessA == 3

    fitnessB = 0
    for other ∈ Sᵦ
        roledict = Dict(:A => phenoB, :B => other)
        mix = Mix(:NG, domain, obscfg, roledict)
        o = stir(mix)
        fitnessB += getscore(:B, 1, o)
    end

    @test fitnessB == 0
end


@testset "NGFocusing" begin
    domain = NGFocusing()
    obscfg = NGObsConfig()

    phenoA = VectorPheno(:A, 1, [4, 16])
    phenoB = VectorPheno(:B, 1, [5, 14])
    roledict = Dict(:A => phenoA, :B => phenoB)
    o = stir(Mix(:NG, domain, obscfg, roledict))
    @test getscore(:A, 1, o) == true

    phenoB = VectorPheno(:B, 1, [5, 16])
    roledict = Dict(:A => phenoA, :B => phenoB)
    o = stir(Mix(:NG, domain, obscfg, roledict))
    @test getscore(:A, 1, o) == false

    phenoA = VectorPheno(:A, 1, [5, 16, 8])
    phenoB = VectorPheno(:B, 1, [4, 16, 6])
    roledict = Dict(:A => phenoA, :B => phenoB)
    o = stir(Mix(:NG, domain, obscfg, roledict))
    @test getscore(:A, 1, o) == true
end


@testset "NGRelativism" begin
    domain = NGRelativism()
    obscfg = NGObsConfig()

    a = VectorPheno(:A, 1, [1, 6])
    b = VectorPheno(:B, 1, [4, 5])
    c = VectorPheno(:C, 1, [2, 4])

    o = stir(Mix(:NG, domain, obscfg, Dict(:A => a, :B => b)))
    @test getscore(:A, 1, o) == true

    o = stir(Mix(:NG, domain, obscfg, Dict(:A => b, :B => c)))
    @test getscore(:B, 1, o) == true

    o = stir(Mix(:NG, domain, obscfg, Dict(:A => c, :B => a)))
    @test getscore(:C, 1, o) == true
end

@testset "Spawner" begin
    rng = StableRNG(42)
    sc = SpawnCounter()
    spawner = testspawner(rng, :A)
    species = Species(spawner, false)
    indivs = sort(collect(species.pop), by = i -> i.iid)
    @test length(indivs) == 10
    @test all([:A == indivs[i].spid for i in 1:10])
    @test sum([sum(genotype(indiv).genes) for indiv in values(indivs)]) == 0

    vets = dummyvets(species)

    species = spawner(vets)
    @test length(species.children) == 10
    @test sort(collect([indiv.iid for indiv in species.children])) == collect(11:20)
end
 
@testset "AllvsAllOrder/SerialConfig" begin
    rng = StableRNG(42)
    spawnerA = testspawner(rng, :A)
    spawnerB = testspawner(rng, :B)

    speciesA = Species(:A, spawnerA.icfg(5, false), spawnerA.icfg(5, true))
    speciesB = Species(:B, spawnerB.icfg(5, false), spawnerB.icfg(5, true))
    allsp = Set([speciesA, speciesB])

    order = testorder()
    recipes = order(speciesA, speciesB)
    @test length(recipes) == 100
    jobcfg = SerialJobConfig()
    job = jobcfg(allsp, order, recipes)
    outcomes = perform(job)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    vetdict = Dict(sp.spid => sp for sp in allvets)
    @test all(fitness(vet) == 0 for vet in vetdict[:A].pop)
    @test all(fitness(vet) == 5 for vet in vetdict[:A].children)
    @test all(fitness(vet) == 0 for vet in vetdict[:B].pop)
    @test all(fitness(vet) == 5 for vet in vetdict[:B].children)

    newsp = spawnerA(allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))

    newsp = spawnerB(allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))
end


@testset "AllvsAllOrder/ParallelJobConfig" begin
    rng = StableRNG(42)
    spawnerA = testspawner(rng, :A)
    spawnerB = testspawner(rng, :B)
    speciesA = Species(:A, spawnerA.icfg(5, false), spawnerA.icfg(5, true))
    speciesB = Species(:B, spawnerB.icfg(5, false), spawnerB.icfg(5, true))
    allsp = Set([speciesA, speciesB])
    order = testorder()
    recipes = order(speciesA, speciesB)
    @test length(recipes) == 100

    jobcfg = ParallelJobConfig(n_jobs = 5)
    jobs = jobcfg(allsp, order, recipes)
    @test length(jobs) == 5
    @test all(length(job.recipes) == 20 for job in jobs)
    outcomes = union([perform(job) for job in jobs]...)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    vetdict = Dict(sp.spid => sp for sp in allvets)
    @test all(fitness(vet) == 5 for vet in vetdict[:A].children)
    @test all(fitness(vet) == 0 for vet in vetdict[:B].pop)
    @test all(fitness(vet) == 5 for vet in vetdict[:B].children)

    newsp = spawnerA(allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))

    newsp = spawnerB(allvets)
    @test Set(indiv.iid for indiv in newsp.pop) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in newsp.children) == Set(collect(11:15))
end


@testset "Outcomes: Vector Pheno" begin
    rng = StableRNG(123)

    spawnerA = testspawner(rng, :A; n_pop = 10, width = 100)
    spawnerB = testspawner(rng, :B; n_pop = 10, width = 100)
    speciesA = Species(:A, spawnerA.icfg(10, true))
    speciesB = Species(:B, spawnerB.icfg(10, false))
    allsp = Set([speciesA, speciesB])
    order = vecorder()
    recipes = order(allsp)
    @test length(recipes) == 100

    jobcfg = SerialJobConfig()
    work = jobcfg(allsp, Set([order]), recipes)
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
    order = testorder()
    speciesA = Species(spawnerA, false)
    speciesB = Species(spawnerB, false)
    
    allsp = Set([speciesA, speciesB])
    recipes = order(allsp)
    @test length(recipes) == 2500
    jobcfg = SerialJobConfig()
    work = jobcfg(allsp, order, recipes)
    outcomes = perform(work)
    allvets = makevets(allsp, outcomes)
    newspA = spawnerA(allvets)
    newspB = spawnerB(allvets)

    allsp = Set([newspA, newspB])
    recipes = order(allsp)
    @test length(recipes) == 10000
    work = jobcfg(allsp, order, recipes)
    outcomes = perform(work)
    allvets = makevets(allsp, outcomes)
    newspA = spawnerA(allvets)
    newspB = spawnerB(allvets)
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
            testspawner(rng, :A, n_pop = 100, width = 100),
            testspawner(rng, :B, n_pop = 100, width = 100),
        ]),
        loggers = Set([SpeciesLogger()]))
    gen = UInt16(1)
    allsp = coev_cfg()
    while gen < 200
        println(gen)
        allsp = coev_cfg(gen, allsp)
        gen += UInt16(1)
    end
end

end