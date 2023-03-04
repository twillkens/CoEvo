using Test
using Random
using StableRNGs
using CoEvo
include("util.jl")


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

    icfg = VectorIndivConfig(
        spid = :A,
        dtype = Bool,
        width = 100
    )
    es = EvoState(42, [:A])
    indivs = sort(collect(values(icfg(es, 10, false))), by = i -> i.iid)

    indiv = indivs[1]
    @test length(indiv.genes) == 100
    @test sum(genotype(indiv).genes) == 0

    indiv = indivs[10]
    @test indiv.iid == 10
    @test indiv.genes[1].gid == 901
    @test indiv.genes[100].gid == 1000
    @test sum(genotype(indiv).genes) == 0

    indivs = sort(collect(values(icfg(es, 10, true))), by = i -> i.iid)
    indiv = indivs[1]
    @test sum(genotype(indiv).genes) == 100

    indivs = icfg(es, 5)
    for indiv in values(indivs)
        @test sum(genotype(indiv).genes) != 0
        @test sum(genotype(indiv).genes) != 100
    end
end

@testset "NGGradient" begin
    domain = NGGradient()
    obscfg = NGObsConfig()

    phenoA = ScalarPheno(:A, 1, 4)
    phenoB = ScalarPheno(:B, 1, 5)
    mix = Mix(:NG, domain, obscfg, [phenoA, phenoB])
    o = stir(mix)
    @test getscore(:A, 1, o) == false
    @test getscore(:B, 1, o) == true

    Sₐ = Set(ScalarPheno(:C, i, x) for (i, x) in enumerate(1:3))
    Sᵦ = Set(ScalarPheno(:D, i, x) for (i, x) in enumerate(6:8))
    
    fitnessA = 0
    for other ∈ Sₐ
        mix = Mix(:NG, domain, obscfg, [phenoA, other])
        o = stir(mix)
        fitnessA += getscore(:A, 1, o)
    end

    @test fitnessA == 3

    fitnessB = 0
    for other ∈ Sᵦ
        mix = Mix(:NG, domain, obscfg, [phenoB, other])
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
    o = stir(Mix(:NG, domain, obscfg, [phenoA, phenoB]))
    @test getscore(:A, 1, o) == true

    phenoB = VectorPheno(:B, 1, [5, 16])
    o = stir(Mix(:NG, domain, obscfg, [phenoA, phenoB]))
    @test getscore(:A, 1, o) == false

    phenoA = VectorPheno(:A, 1, [5, 16, 8])
    phenoB = VectorPheno(:B, 1, [4, 16, 6])
    o = stir(Mix(:NG, domain, obscfg, [phenoA, phenoB]))
    @test getscore(:A, 1, o) == true
end

@testset "NGRelativism" begin
    domain = NGRelativism()
    obscfg = NGObsConfig()

    a = VectorPheno(:A, 1, [1, 6])
    b = VectorPheno(:B, 1, [4, 5])
    c = VectorPheno(:C, 1, [2, 4])

    o = stir(Mix(:NG, domain, obscfg, [a, b]))
    @test getscore(:A, 1, o) == true

    o = stir(Mix(:NG, domain, obscfg, [b, c]))
    @test getscore(:B, 1, o) == true

    o = stir(Mix(:NG, domain, obscfg, [c, a]))
    @test getscore(:C, 1, o) == true
end

@testset "Spawner" begin
    spawners = Dict(testspawner(:A))
    es = EvoState(42, spawners)
    species = Species(es, spawners[:A], false)
    indivs = sort(collect(values(species.children)), by = i -> i.iid)
    @test length(indivs) == 10
    @test all([:A == indivs[i].spid for i in 1:10])
    @test sum([sum(genotype(indiv).genes) for indiv in values(indivs)]) == 0

    vets = dummyvets(species)

    species = spawners[:A](es, Dict(vets.spid => vets))
    @test length(species.children) == 10
    @test sort(collect([indiv.iid for indiv in values(species.children)])) == collect(11:20)
end
 
@testset "AllvsAllOrder/SerialConfig" begin
    spawners = Dict(
            testspawner(:A, npop = 5),
            testspawner(:B, npop = 5)
    )
    es = EvoState(42, spawners)
    phenocfg = SumPhenoConfig()

    allsp = Dict(
        :A => Species(
            :A, phenocfg, spawners[:A].icfg(es, 5, false), spawners[:A].icfg(es, 5, true)),
        :B => Species(
            :B, phenocfg, spawners[:B].icfg(es, 5, false), spawners[:B].icfg(es, 5, true))
    )
    order = testorder()
    recipes = order(allsp[:A], allsp[:B])
    @test length(recipes) == 100
    jobcfg = SerialPhenoJobConfig()
    job = jobcfg(allsp, order, recipes)
    outcomes = perform(job)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    @test all(fitness(vet) == 0 for (_, vet) in allvets[:A].pop)
    @test all(fitness(vet) == 5 for (_, vet) in allvets[:A].children)
    @test all(fitness(vet) == 0 for (_, vet) in allvets[:B].pop)
    @test all(fitness(vet) == 5 for (_, vet) in allvets[:B].children)

    newsp = spawners[:A](es, allvets)
    @test Set(indiv.iid for indiv in values(newsp.pop)) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in values(newsp.children)) == Set(collect(11:15))

    newsp = spawners[:B](es, allvets)
    @test Set(indiv.iid for indiv in values(newsp.pop)) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in values(newsp.children)) == Set(collect(11:15))
end

@testset "AllvsAllOrder/ParallelJobConfig" begin
    spawners = Dict(
        testspawner(:A, npop = 5),
        testspawner(:B, npop = 5),
    )
    es = EvoState(42, spawners)
    phenocfg = SumPhenoConfig()

    allsp = Dict(
        :A => Species(
            :A, phenocfg, spawners[:A].icfg(es, 5, false), spawners[:A].icfg(es, 5, true)
        ),
        :B => Species(
            :B, phenocfg, spawners[:B].icfg(es, 5, false), spawners[:B].icfg(es, 5, true)
        )
    )
    order = testorder()
    recipes = order(allsp[:A], allsp[:B])
    @test length(recipes) == 100
    jobcfg = ParallelPhenoJobConfig(njobs = 5)
    jobs = jobcfg(allsp, order, recipes)
    @test length(jobs) == 5
    @test all(length(job.recipes) == 20 for job in jobs)
    outcomes = vcat([perform(job) for job in jobs]...)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    @test all(fitness(vet) == 5 for (_, vet) in allvets[:A].children)
    @test all(fitness(vet) == 0 for (_, vet) in allvets[:B].pop)
    @test all(fitness(vet) == 5 for (_, vet) in allvets[:B].children)

    newsp = spawners[:A](es, allvets)
    @test Set(indiv.iid for indiv in values(newsp.pop)) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in values(newsp.children)) == Set(collect(11:15))

    newsp = spawners[:B](es, allvets)
    @test Set(indiv.iid for indiv in values(newsp.pop)) == Set(collect(6:10))
    @test Set(indiv.iid for indiv in values(newsp.children)) == Set(collect(11:15))
end

@testset "Outcomes: Vector Pheno" begin
    spawners = Dict(
        testspawner(:A; npop = 10, width = 100),
        testspawner(:B; npop = 10, width = 100)
    )
    es = EvoState(42, spawners)
    phenocfg = SubvecPhenoConfig(subvec_width = 10)

    speciesA = Species(:A, phenocfg, spawners[:A].icfg(es, 10, true))
    speciesB = Species(:B, phenocfg, spawners[:B].icfg(es, 10, false))
    allsp = Dict(:A => speciesA, :B => speciesB)
    order = vecorder()
    recipes = order(allsp)
    @test length(recipes) == 100

    jobcfg = SerialPhenoJobConfig()
    work = jobcfg(allsp, order, recipes)
    outcomes = perform(work)
    @test length(outcomes) == 100
    allvets = makevets(allsp, outcomes)
    @test sum(fitness(vet) for (_, vet) in allvets[:A].children) == 100
    @test sum(fitness(vet) for (_, vet) in allvets[:B].children) == 0
end

@testset "Generational/Roulette/Bitflip" begin
    spawners = Dict(
        roulettespawner(:A, npop = 50, width = 100),
        roulettespawner(:B, npop = 50, width = 100)
    )
    es = EvoState(42, spawners)
    phenocfg = SumPhenoConfig()
    order = testorder()
    allsp = Dict(
        :A => Species(:A, phenocfg, spawners[:A].icfg(es, 50, false)), 
        :B => Species(:B, phenocfg, spawners[:B].icfg(es, 50, false))
    )
    
    recipes = order(allsp)
    @test length(recipes) == 2500
    jobcfg = SerialPhenoJobConfig()
    work = jobcfg(allsp, order, recipes)
    outcomes = perform(work)
    allvets = makevets(allsp, outcomes)
    
    newspA = spawners[:A](es, allvets)
    newspB = spawners[:B](es, allvets)

    allsp = Dict(:A => newspA, :B => newspB)

    recipes = order(allsp)
    @test length(recipes) == 10000
    work = jobcfg(allsp, order, recipes)
    outcomes = perform(work)
    allvets = makevets(allsp, outcomes)
    newspA = spawners[:A](es, allvets)
    newspB = spawners[:B](es, allvets)
    @test length(newspA.pop) == 50
    @test length(newspA.children) == 50
end
# 
@testset "Coev/Unfreeze" begin
    # RNG #
    spawners = Dict(
        testspawner(:A; npop = 100, width = 100),
        testspawner(:B; npop = 100, width = 100),
    )
    eco = :NumbersTest
    trial = 1
    c1 = CoevConfig(;
        eco = eco,
        trial = trial,
        seed = 42,
        jobcfg = SerialPhenoJobConfig(),
        orders = Dict(:NG => testorder()),
        spawners = spawners,
    )
    gen = 1
    lastsp = nothing
    allsp = c1()
    while gen < 10
        lastsp = allsp
        allsp = c1(gen, allsp)
        gen += 1
    end

    gen, c2, allsp = unfreeze("archives/NumbersTest/1.jld2")
    @test gen == 10
    @test c1.eco == c2.eco
    @test c1.trial == c2.trial
    @test c1.evostate.rng == c2.evostate.rng
    @test c1.evostate.counters[:A].iid == c2.evostate.counters[:A].iid + 100
    @test c1.evostate.counters[:A].gid == c2.evostate.counters[:A].gid 
    @test c1.evostate.counters[:B].iid == c2.evostate.counters[:B].iid + 100
    @test c1.evostate.counters[:B].gid == c2.evostate.counters[:B].gid 
    @test c1.jobcfg == c2.jobcfg
    s1, s2 = c1.spawners[:A], c2.spawners[:A]
    @test all(getproperty(s1, fname) == getproperty(s2, fname) for fname in fieldnames(Spawner))
    o1, o2 = c1.orders[:NG], c2.orders[:NG]
    @test all(getproperty(o1, fname) == getproperty(o2, fname)
        for fname in fieldnames(AllvsAllPlusOrder))
    @test c1.loggers == c2.loggers
    rm("archives/NumbersTest", force = true, recursive = true)
end

end