@testset "Simulate" begin
@testset "newsimple" begin
    tname = :simple
    domain = LingPredGame(MatchCoop())
    obscfg = LingPredObsConfig()
    ikey = IndivKey(:A, 1) 
    start = "A0"
    ones = Set(["A1"])
    zeros = Set(["A0"])
    links = LinkDict(
        ("A0", 0)  => "A0",
        ("A0", 1)  => "A1",
        ("A1", 0)  => "A0",
        ("A1", 1)  => "A1",
    )
    fsm1 = FSMSetPheno(ikey,start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = "B0"
    ones = Set(["B1"])
    zeros = Set(["B0"])
    links = LinkDict(
                ("B0", 0)  => "B1",
                ("B0", 1)  => "B0",
                ("B1", 0)  => "B1",
                ("B1", 1)  => "B0",
                )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)

    oset = stir(Mix(tname, domain, obscfg, [fsm1, fsm2]))
    omin = stir(Mix(tname, domain, obscfg, [FSMMinPheno(fsm1), FSMMinPheno(fsm2)]))

    @test oset.rdict[fsm1.ikey].second ≈ 0.5 ≈ omin.rdict[fsm1.ikey].second
    @test oset.rdict[fsm2.ikey].second ≈ 0.5 ≈ omin.rdict[fsm2.ikey].second
    @test oset.obs.outs[fsm1.ikey] == [0, 0, 1, 1, 0] == omin.obs.outs[fsm1.ikey]
    @test oset.obs.outs[fsm2.ikey] == [0, 1, 1, 0, 0] == omin.obs.outs[fsm2.ikey]
    @test oset.obs.states[fsm1.ikey] == ["A0", "A0", "A1", "A1", "A0"] == omin.obs.states[fsm1.ikey]
    @test oset.obs.states[fsm2.ikey] == ["B0", "B1", "B1", "B0", "B0"] == omin.obs.states[fsm2.ikey]
    @test oset.obs.outs[fsm1.ikey][oset.obs.loopstart:end - 1] == [0, 0, 1, 1] == omin.obs.outs[fsm1.ikey][omin.obs.loopstart:end - 1]
    @test oset.obs.outs[fsm2.ikey][oset.obs.loopstart:end - 1] == [0, 1, 1, 0] == omin.obs.outs[fsm2.ikey][omin.obs.loopstart:end - 1]
end

@testset "newsimpleint" begin
    tname = :simple
    domain = LingPredGame(MatchCoop())
    obscfg = LingPredObsConfig()
    ikey = IndivKey(:A, 1) 
    start = 0
    ones = Set([1])
    zeros = Set([0])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 0,
        (0, 1)  => 1,
        (1, 0)  => 0,
        (1, 1)  => 1,
    )
    fsm1 = FSMSetPheno(ikey,start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = 0
    ones = Set([1])
    zeros = Set([0])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 1,
        (0, 1)  => 0,
        (1, 0)  => 1,
        (1, 1)  => 0,
    )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    #outcome = stir(mix)

    oset = stir(Mix(tname, domain, obscfg, [fsm1, fsm2]))
    omin = stir(Mix(tname, domain, obscfg, [FSMMinPheno(fsm1), FSMMinPheno(fsm2)]))

    @test oset.rdict[fsm1.ikey].second ≈ 0.5 ≈ omin.rdict[fsm1.ikey].second
    @test oset.rdict[fsm2.ikey].second ≈ 0.5 ≈ omin.rdict[fsm2.ikey].second
    @test oset.obs.outs[fsm1.ikey] == [0, 0, 1, 1, 0] == omin.obs.outs[fsm1.ikey]
    @test oset.obs.outs[fsm2.ikey] == [0, 1, 1, 0, 0] == omin.obs.outs[fsm2.ikey]
    @test oset.obs.states[fsm1.ikey] == [0, 0, 1, 1, 0] == omin.obs.states[fsm1.ikey]
    @test oset.obs.states[fsm2.ikey] == [0, 1, 1, 0, 0] == omin.obs.states[fsm2.ikey]
    @test oset.obs.outs[fsm1.ikey][oset.obs.loopstart:end - 1] == [0, 0, 1, 1] == omin.obs.outs[fsm1.ikey][omin.obs.loopstart:end - 1]
    @test oset.obs.outs[fsm2.ikey][oset.obs.loopstart:end - 1] == [0, 1, 1, 0] == omin.obs.outs[fsm2.ikey][omin.obs.loopstart:end - 1]
end


@testset "newcoop1" begin
    tname = :newcoop1
    domain = LingPredGame(MatchCoop())
    obscfg = LingPredObsConfig()
    start = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    ikey = IndivKey(:A, 1)
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = "B0"
    zeros = Set(["B0"])
    ones = Set(["B1"])
    links = LinkDict(
                ("B0", 0)  => "B0",
                ("B0", 1)  => "B1",
                ("B1", 0)  => "B0",
                ("B1", 1)  => "B1",
                )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)

    @test outcome.rdict[fsm1.ikey].second ≈ 1/3
    @test outcome.rdict[fsm2.ikey].second ≈ 1/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 0, 1]
    @test outcome.obs.outs[fsm2.ikey] == [0, 0, 1, 1, 0]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 0]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [0, 1, 1]
    @test outcome.obs.states[fsm1.ikey] == ["A0", "A1", "A1", "A0", "A1"]
    @test outcome.obs.states[fsm2.ikey] == ["B0", "B0", "B1", "B1", "B0"]
end

@testset "newcoopint1" begin
    tname = :newcoopint1 
    domain = LingPredGame(MatchCoop())
    obscfg = LingPredObsConfig()
    start = 0
    zeros = Set([0])
    ones = Set([1])
    ikey = IndivKey(:A, 1)
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 1,
        (0, 1)  => 1,
        (1, 0)  => 1,
        (1, 1)  => 0,
    )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = 0
    zeros = Set([0])
    ones = Set([1])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 0,
        (0, 1)  => 1,
        (1, 0)  => 0,
        (1, 1)  => 1,
    )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)
    @test outcome.rdict[fsm1.ikey].second ≈ 1/3
    @test outcome.rdict[fsm2.ikey].second ≈ 1/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 0, 1]
    @test outcome.obs.outs[fsm2.ikey] == [0, 0, 1, 1, 0]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 0]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [0, 1, 1]
    @test outcome.obs.states[fsm1.ikey] == [0, 1, 1, 0, 1]
    @test outcome.obs.states[fsm2.ikey] == [0, 0, 1, 1, 0]
end


@testset "newcomp1" begin
    tname = :newcomp1
    domain = LingPredGame(MismatchComp())
    obscfg = LingPredObsConfig()
    start = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    ikey = IndivKey(:A, 1)
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = "B0"
    zeros = Set(["B0"])
    ones = Set(["B1"])
    links = LinkDict(
                ("B0", 0)  => "B0",
                ("B0", 1)  => "B1",
                ("B1", 0)  => "B0",
                ("B1", 1)  => "B1",
                )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)

    @test outcome.rdict[fsm1.ikey].second ≈ 2/3
    @test outcome.rdict[fsm2.ikey].second ≈ 1/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 0, 1]
    @test outcome.obs.outs[fsm2.ikey] == [0, 0, 1, 1, 0]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 0]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [0, 1, 1]
    @test outcome.obs.states[fsm1.ikey] == ["A0", "A1", "A1", "A0", "A1"]
end

@testset "newcomp1int" begin
    tname = :newcomp1int
    domain = LingPredGame(MismatchComp())
    obscfg = LingPredObsConfig()
    start = 0
    zeros = Set([0])
    ones = Set([1])
    ikey = IndivKey(:A, 1)
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 1,
        (0, 1)  => 1,
        (1, 0)  => 1,
        (1, 1)  => 0,
    )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = 0
    zeros = Set([0])
    ones = Set([1])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 0,
        (0, 1)  => 1,
        (1, 0)  => 0,
        (1, 1)  => 1,
    )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)
    @test outcome.rdict[fsm1.ikey].second ≈ 2/3
    @test outcome.rdict[fsm2.ikey].second ≈ 1/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 0, 1]
    @test outcome.obs.outs[fsm2.ikey] == [0, 0, 1, 1, 0]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 0]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [0, 1, 1]
    @test outcome.obs.states[fsm1.ikey] == [0, 1, 1, 0, 1]
end

@testset "newcoop2" begin
    tname = :newcoop2
    domain = LingPredGame(MatchCoop())
    obscfg = LingPredObsConfig()
    start = "a"
    zeros = Set(["a"])
    ones = Set(["b", "c"])
    ikey = IndivKey(:A, 1)
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "c",
                ("b", 1)  => "b",
                ("c", 0)  => "c",
                ("c", 1)  => "b",
                )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = "a"
    zeros = Set(["b"])
    ones = Set(["a", "c"])
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "b",
                ("b", 1)  => "c",
                ("c", 0)  => "a",
                ("c", 1)  => "a",
                )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)

    @test outcome.rdict[fsm1.ikey].second ≈ 2/3
    @test outcome.rdict[fsm2.ikey].second ≈ 2/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey] == [1, 1, 0, 1, 1]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [1, 0, 1]
    @test outcome.obs.states[fsm1.ikey] == ["a", "b", "b", "c", "b"]
    @test outcome.obs.states[fsm2.ikey] == ["a", "a", "b", "c", "a"]
end

@testset "newcoop2int" begin
    tname = :newcoop2int
    domain = LingPredGame(MatchCoop())
    obscfg = LingPredObsConfig()
    start = 0
    zeros = Set([0])
    ones = Set([1, 2])
    ikey = IndivKey(:A, 1)
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 0,
        (0, 1)  => 1,
        (1, 0)  => 2,
        (1, 1)  => 1,
        (2, 0)  => 2,
        (2, 1)  => 1,
    )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = 0
    zeros = Set([1])
    ones = Set([0, 2])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 0,
        (0, 1)  => 1,
        (1, 0)  => 1,
        (1, 1)  => 2,
        (2, 0)  => 0,
        (2, 1)  => 0,
    )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)

    @test outcome.rdict[fsm1.ikey].second ≈ 2/3
    @test outcome.rdict[fsm2.ikey].second ≈ 2/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey] == [1, 1, 0, 1, 1]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [1, 0, 1]
    @test outcome.obs.states[fsm1.ikey] == [0, 1, 1, 2, 1]
    @test outcome.obs.states[fsm2.ikey] == [0, 0, 1, 2, 0]
end


@testset "newcomp2" begin
    tname = :newcomp2
    domain = LingPredGame(MatchComp())
    obscfg = LingPredObsConfig()
    start = "a"
    zeros = Set(["a"])
    ones = Set(["b", "c"])
    ikey = IndivKey(:A, 1)
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "c",
                ("b", 1)  => "b",
                ("c", 0)  => "c",
                ("c", 1)  => "b",
                )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = "a"
    zeros = Set(["b"])
    ones = Set(["a", "c"])
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "b",
                ("b", 1)  => "c",
                ("c", 0)  => "a",
                ("c", 1)  => "a",
                )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)

    @test outcome.rdict[fsm1.ikey].second ≈ 2/3
    @test outcome.rdict[fsm2.ikey].second ≈ 1/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey] == [1, 1, 0, 1, 1]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [1, 0, 1]
    @test outcome.obs.states[fsm1.ikey] == ["a", "b", "b", "c", "b"]
    @test outcome.obs.states[fsm2.ikey] == ["a", "a", "b", "c", "a"]
end

@testset "newcomp2int" begin
    tname = :newcomp2int
    domain = LingPredGame(MatchComp())
    obscfg = LingPredObsConfig()
    start = 0
    zeros = Set([0])
    ones = Set([1, 2])
    ikey = IndivKey(:A, 1)
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 0,
        (0, 1)  => 1,
        (1, 0)  => 2,
        (1, 1)  => 1,
        (2, 0)  => 2,
        (2, 1)  => 1,
    )
    fsm1 = FSMSetPheno(ikey, start, ones, zeros, links)

    ikey = IndivKey(:B, 1)
    start = 0
    zeros = Set([1])
    ones = Set([0, 2])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0)  => 0,
        (0, 1)  => 1,
        (1, 0)  => 1,
        (1, 1)  => 2,
        (2, 0)  => 0,
        (2, 1)  => 0,
    )
    fsm2 = FSMSetPheno(ikey, start, ones, zeros, links)
    mix = Mix(tname, domain, obscfg, [fsm1, fsm2])
    outcome = stir(mix)

    @test outcome.rdict[fsm1.ikey].second ≈ 2/3
    @test outcome.rdict[fsm2.ikey].second ≈ 1/3
    @test outcome.obs.outs[fsm1.ikey] == [0, 1, 1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey] == [1, 1, 0, 1, 1]
    @test outcome.obs.outs[fsm1.ikey][outcome.obs.loopstart:end - 1] == [1, 1, 1]
    @test outcome.obs.outs[fsm2.ikey][outcome.obs.loopstart:end - 1] == [1, 0, 1]
    @test outcome.obs.states[fsm1.ikey] == [0, 1, 1, 2, 1]
    @test outcome.obs.states[fsm2.ikey] == [0, 0, 1, 2, 0]
end

end