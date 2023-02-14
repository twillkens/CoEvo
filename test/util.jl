export testspawner, roulettespawner, testorder, vecorder, dummyikey, dummytkey, dummyvets

function testspawner(
    rng::AbstractRNG, spid::Symbol;
    npop = 10, width = 10, phenocfg = SumPhenoConfig()
)
    sc = SpawnCounter()
    Spawner(
        spid = spid,
        npop = npop,
        icfg = VectorIndivConfig(
            spid = spid,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = width
        ),
        phenocfg = phenocfg,
        replacer = TruncationReplacer(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(sc = sc),
        mutators = Mutator[]
    )
end

function roulettespawner(
    rng::AbstractRNG, spid::Symbol;
    npop = 50, width = 100, phenocfg = SumPhenoConfig()
)
    sc = SpawnCounter()
    Spawner(
        spid = spid,
        npop = npop,
        icfg = VectorIndivConfig(
            spid = spid,
            sc = sc,
            rng = rng,
            dtype = Bool,
            width = width
        ),
        phenocfg = phenocfg,
        replacer = GenerationalReplacer(n_elite = 10),
        selector =  RouletteSelector(rng = rng, μ = npop),
        recombiner = CloneRecombiner(sc = sc),
        mutators = [BitflipMutator(rng = rng, sc = sc, mutrate = 0.05)]
    )
end

function testorder()
    AllvsAllPlusOrder(
        oid = :NG,
        spids = [:A, :B],
        domain = NGGradient(),
        obscfg = NGObsConfig(),
    )
end

function vecorder()
    AllvsAllPlusOrder(
        oid = :NG,
        spids = [:A, :B],
        domain = NGFocusing(),
        obscfg = NGObsConfig(),
    )
end

function dummyikey()
    IndivKey(:spdummy, 1)
end

function dummytkey()
    TestKey(:odummy, dummyikey())
end

function dummyvets(indivs::Dict{IndivKey, <:Individual})
    Dict(ikey => Veteran(ikey, indiv, Dict(dummytkey() => 1))
        for (ikey, indiv) in indivs)
end

function dummyvets(sp::Species)
    Species(sp.spid, sp.phenocfg, dummyvets(sp.pop), dummyvets(sp.children))
end