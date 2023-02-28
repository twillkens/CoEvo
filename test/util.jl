export testspawner, roulettespawner, testorder, vecorder, dummyikey, dummytkey, dummyvets

function testspawner(
    spid::Symbol;
    npop = 10, width = 10, phenocfg = SumPhenoConfig()
)
    spid => Spawner(
        spid = spid,
        npop = npop,
        icfg = VectorIndivConfig(
            spid = spid,
            dtype = Bool,
            width = width
        ),
        phenocfg = phenocfg,
        replacer = TruncationReplacer(npop = npop),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(),
        mutators = Mutator[],
        archiver = VectorIndivArchiver(interval=1)
    )
end

function roulettespawner(
    spid::Symbol;
    npop = 50, width = 100, phenocfg = SumPhenoConfig()
)
    spid => Spawner(
        spid = spid,
        npop = npop,
        icfg = VectorIndivConfig(
            spid = spid,
            dtype = Bool,
            width = width
        ),
        phenocfg = phenocfg,
        replacer = GenerationalReplacer(npop = npop, n_elite = 10),
        selector =  RouletteSelector(μ = npop),
        recombiner = CloneRecombiner(),
        mutators = [BitflipMutator(mutrate = 0.05)],
        archiver = VectorIndivArchiver(interval=1)
    )
end

function testorder(;oid::Symbol = :NG, spids::Vector{Symbol} = [:A, :B])
    AllvsAllPlusOrder(
        oid = oid,
        spids = spids,
        domain = NGGradient(),
        obscfg = NGObsConfig(),
    )
end

function vecorder(; oid::Symbol = :NG, spids::Vector{Symbol} = [:A, :B])
    AllvsAllPlusOrder(
        oid = oid,
        spids = spids,
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