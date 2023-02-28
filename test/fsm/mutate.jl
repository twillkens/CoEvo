# using Test
# using Random
# using StableRNGs
# include("../../src/Coevolutionary.jl")
# using .Coevolutionary

verbose = false

@testset "Mutation" begin

function printadd(fsm_before, fsm, label, truedest, falsedest)
    if verbose
        println("---------")
        println("Test: addstate!\n")
        println("FSM before")
        printFSM(fsm_before)
        println()
        println("New state label: ", label)
        println("New state 0-dest: ", falsedest)
        println("New state 1-dest: ", truedest)
        println()
        println("FSM after")
        printFSM(fsm)
        println()
    end
end

@testset "addstate" begin
    ikey = IndivKey(:addstate, 1)
    start = "1"
    ones = Set(["1", "2", "3", "4"])
    zeros = Set(["5"])
    links = LinkDict(
                ("1", 0) => "2",
                ("1", 1) => "3",
                ("2", 0) => "2",
                ("2", 1) => "4",
                ("3", 0) => "2",
                ("3", 1) => "3",
                ("4", 0) => "2",
                ("4", 1) => "5",
                ("5", 0) => "2",
                ("5", 1) => "3",
                )

    fsm_before = FSMIndiv(ikey, start, ones, zeros, links)
    label = false
    truedest = "3"
    falsedest = "5"
    newstate = "6"
    fsm = addstate(fsm_before, newstate, label, truedest, falsedest)

    @test fsm.start == "1"
    @test length(fsm.links) == 12
    @test fsm.ones == Set(["1", "2", "3", "4"])
    @test fsm.zeros == Set(["5", "6"])
    @test fsm.links[("1", 0)] == "2"
    @test fsm.links[("1", 1)] == "3"
    @test fsm.links[("2", 0)] == "2"
    @test fsm.links[("2", 1)] == "4"
    @test fsm.links[("3", 0)] == "2"
    @test fsm.links[("3", 1)] == "3"
    @test fsm.links[("4", 0)] == "2"
    @test fsm.links[("4", 1)] == "5"
    @test fsm.links[("5", 0)] == "2"
    @test fsm.links[("5", 1)] == "3"
    @test fsm.links[("6", 0)] == "5"
    @test fsm.links[("6", 1)] == "3"

    min1 = minimize(fsm)

    @test min1.start == "1/3"
    @test length(min1.links) == 8
    @test min1.ones == Set(["1/3", "2/", "4/"])
    @test min1.zeros == Set(["5/"])
    @test min1.links[("1/3", 0)] == "2/"
    @test min1.links[("1/3", 1)] == "1/3"
    @test min1.links[("2/",  0)] == "2/"
    @test min1.links[("2/",  1)] == "4/"
    @test min1.links[("4/",  0)] == "2/"
    @test min1.links[("4/",  1)] == "5/"
    @test min1.links[("5/",  0)] == "2/"
    @test min1.links[("5/",  1)] == "1/3"

    printadd(fsm_before, fsm, label, truedest, falsedest)
end

@testset "rmstate" begin
    ikey = IndivKey(:rmstate, 1)
    start = "1"
    ones = Set(["1", "2", "3", "4"])
    zeros = Set(["5"])
    links = LinkDict(
                ("1", 0) => "2",
                ("1", 1) => "3",
                ("2", 0) => "2",
                ("2", 1) => "4",
                ("3", 0) => "2",
                ("3", 1) => "3",
                ("4", 0) => "2",
                ("4", 1) => "5",
                ("5", 0) => "2",
                ("5", 1) => "3",
                )

    fsm_before = FSMIndiv(ikey, start, ones, zeros, links)

    todelete = "3"
    newlinks = LinkDict(
                    ("1", 1) => "1",
                    ("5", 1) => "4",
                    )
    newstart = "1"
    fsm = rmstate(fsm_before, todelete, newstart, newlinks)

    @test fsm.start == "1"
    @test length(fsm.links) == 8
    @test fsm.ones == Set(["1", "2", "4"])
    @test fsm.zeros == Set(["5"])
    @test fsm.links[("1", 0)] == "2"
    @test fsm.links[("1", 1)] == "1"
    @test fsm.links[("2", 0)] == "2"
    @test fsm.links[("2", 1)] == "4"
    @test fsm.links[("4", 0)] == "2"
    @test fsm.links[("4", 1)] == "5"
    @test fsm.links[("5", 0)] == "2"
    @test fsm.links[("5", 1)] == "4"

    min1 = minimize(fsm)

    @test min1.start == "1/"
    @test length(min1.links) == 8
    @test min1.ones == Set(["1/", "2/", "4/"])
    @test min1.zeros == Set(["5/"])
    @test min1.links[("1/", 0)] == "2/"
end


@testset "rmstate2" begin
    ikey = IndivKey(:rmstate2, 1)
    start = "1"
    ones = Set(["1", "2", "6"])
    zeros = Set(["3", "4", "5"])
    links = LinkDict(
                ("1", 0) => "2",
                ("1", 1) => "3",
                ("2", 0) => "1",
                ("2", 1) => "4",
                ("3", 0) => "5",
                ("3", 1) => "6",
                ("4", 0) => "5",
                ("4", 1) => "6",
                ("5", 0) => "5",
                ("5", 1) => "6",
                ("6", 0) => "6",
                ("6", 1) => "6",
                )

    fsm_before = FSMIndiv(ikey, start, ones, zeros, links)

    todelete = "1"
    newlinks = LinkDict(
                    ("2", 0) => "5",
                    )
    newstart = "5"
    fsm = rmstate(fsm_before, todelete, newstart, newlinks)

    @test fsm.start == "5"
    @test length(fsm.links) == 10
    @test fsm.ones == Set(["2", "6"])
    @test fsm.zeros == Set(["3", "4", "5"])
    @test fsm.links[("2", 0)] == "5"
    @test fsm.links[("2", 1)] == "4"
    @test fsm.links[("3", 0)] == "5"
    @test fsm.links[("3", 1)] == "6"
    @test fsm.links[("4", 0)] == "5"
    @test fsm.links[("4", 1)] == "6"
    @test fsm.links[("5", 0)] == "5"
    @test fsm.links[("5", 1)] == "6"
    @test fsm.links[("6", 0)] == "6"
    @test fsm.links[("6", 1)] == "6"
end

@testset "changelink" begin
    ikey = IndivKey(:changelink, 1)
    start = "1"
    curr = "1"
    ones = Set(["1", "2", "6"])
    zeros = Set(["3", "4", "5"])
    links = LinkDict(
                ("1", 0) => "2",
                ("1", 1) => "3",
                ("2", 0) => "1",
                ("2", 1) => "4",
                ("3", 0) => "5",
                ("3", 1) => "6",
                ("4", 0) => "5",
                ("4", 1) => "6",
                ("5", 0) => "5",
                ("5", 1) => "6",
                ("6", 0) => "6",
                ("6", 1) => "6",
                )

    fsm_before = FSMIndiv(ikey, start, ones, zeros, links)

    state = "3"
    newdest = "1"
    bit = true

    fsm = changelink(fsm_before, state, newdest, bit)

    @test fsm.start == "1"
    @test length(fsm.links) == 12
    @test fsm.ones == Set(["1", "2", "6"])
    @test fsm.zeros == Set(["3", "4", "5"])
    @test fsm.links[("1", 0)] == "2"
    @test fsm.links[("1", 1)] == "3"
    @test fsm.links[("2", 0)] == "1"
    @test fsm.links[("2", 1)] == "4"
    @test fsm.links[("3", 0)] == "5"
    @test fsm.links[("3", 1)] == "1"
    @test fsm.links[("4", 0)] == "5"
    @test fsm.links[("4", 1)] == "6"
    @test fsm.links[("5", 0)] == "5"
    @test fsm.links[("5", 1)] == "6"
    @test fsm.links[("6", 0)] == "6"
    @test fsm.links[("6", 1)] == "6"
end

@testset "changelabel" begin
    ikey = IndivKey(:changelabel, 1)
    start = "1"
    curr = "1"
    ones = Set(["1", "2", "6"])
    zeros = Set(["3", "4", "5"])
    links = LinkDict(
                ("1", 0) => "2",
                ("1", 1) => "3",
                ("2", 0) => "1",
                ("2", 1) => "4",
                ("3", 0) => "5",
                ("3", 1) => "6",
                ("4", 0) => "5",
                ("4", 1) => "6",
                ("5", 0) => "5",
                ("5", 1) => "6",
                ("6", 0) => "6",
                ("6", 1) => "6",
                )

    fsm_before = FSMIndiv(ikey, start, ones, zeros, links)

    state = "3"

    fsm = changelabel(fsm_before, state)

    @test fsm.start == "1"
    @test length(fsm.links) == 12
    @test fsm.ones == Set(["1", "2", "6", "3"])
    @test fsm.zeros == Set(["4", "5"])
    @test fsm.links[("1", 0)] == "2"
    @test fsm.links[("1", 1)] == "3"
    @test fsm.links[("2", 0)] == "1"
    @test fsm.links[("2", 1)] == "4"
    @test fsm.links[("3", 0)] == "5"
    @test fsm.links[("3", 1)] == "6"
    @test fsm.links[("4", 0)] == "5"
    @test fsm.links[("4", 1)] == "6"
    @test fsm.links[("5", 0)] == "5"
    @test fsm.links[("5", 1)] == "6"
    @test fsm.links[("6", 0)] == "6"
    @test fsm.links[("6", 1)] == "6"
end

@testset "rand-addstate" begin
    ikey = IndivKey(:randaddstate, 1)
    start = "1"
    curr = "1"
    ones = Set(["1", "2", "6"])
    zeros = Set(["3", "4", "5"])
    links = LinkDict(
        ("1", 0) => "2",
        ("1", 1) => "3",
        ("2", 0) => "1",
        ("2", 1) => "4",
        ("3", 0) => "5",
        ("3", 1) => "6",
        ("4", 0) => "5",
        ("4", 1) => "6",
        ("5", 0) => "5",
        ("5", 1) => "6",
        ("6", 0) => "6",
        ("6", 1) => "6",
    )

    fsm = FSMIndiv(ikey, start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    sc.gid = 7
    mutator = LingPredMutator()


    n = 10
    for i in 1:n
        fsm = addstate(rng, sc, fsm)
    end

    @test length(union(fsm.ones, fsm.zeros)) == 16
    @test length(fsm.links) == 32
end

@testset "rand-rmstate" begin
    ikey = IndivKey(:randrmstate, 1)
    start = "0"
    curr = "0"
    ones = Set(["0", "1", "3", "4", "5", "6", "7"])
    zeros = Set(["2"])
    links = LinkDict(
                ("0", 0) => "1",
                ("0", 1) => "5",
                ("1", 0) => "6",
                ("1", 1) => "2",
                ("2", 0) => "0",
                ("2", 1) => "2",
                ("3", 0) => "2",
                ("3", 1) => "6",
                ("4", 0) => "7",
                ("4", 1) => "5",
                ("5", 0) => "2",
                ("5", 1) => "6",
                ("6", 0) => "6",
                ("6", 1) => "4",
                ("7", 0) => "6",
                ("7", 1) => "2",
                )
    fsm = FSMIndiv(ikey, start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    sc.gid = 8
    mutator = LingPredMutator()
    n = 4
    for i in 1:n
        fsm = rmstate(rng, sc, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 4
    @test length(fsm.links) == 8
    for i in 1:50
        fsm = rmstate(rng, sc, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 1
    @test length(fsm.links) == 2
end

@testset "randchangelink" begin
    ikey = IndivKey(:randchangelink, 1)
    start = "0"
    curr = "0"
    ones = Set(["0", "1", "3", "4", "5", "6", "7"])
    zeros = Set(["2"])
    links = LinkDict(
                ("0", 0) => "1",
                ("0", 1) => "5",
                ("1", 0) => "6",
                ("1", 1) => "2",
                ("2", 0) => "0",
                ("2", 1) => "2",
                ("3", 0) => "2",
                ("3", 1) => "6",
                ("4", 0) => "7",
                ("4", 1) => "5",
                ("5", 0) => "2",
                ("5", 1) => "6",
                ("6", 0) => "6",
                ("6", 1) => "4",
                ("7", 0) => "6",
                ("7", 1) => "2",
                )
    fsm = FSMIndiv(ikey, start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    sc.gid = 8
    mutator = LingPredMutator()
    n = 4
    for i in 1:n
        fsm = changelink(rng, sc, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 8
    @test length(fsm.links) == 16
    @test links != fsm.links
end

@testset "randchangelabel" begin
    ikey = IndivKey(:randchangelabel, 1)
    start = "0"
    curr = "0"
    ones = Set(["0", "1", "3", "4", "5", "6", "7"])
    zeros = Set(["2"])
    links = LinkDict(
                ("0", 0) => "1",
                ("0", 1) => "5",
                ("1", 0) => "6",
                ("1", 1) => "2",
                ("2", 0) => "0",
                ("2", 1) => "2",
                ("3", 0) => "2",
                ("3", 1) => "6",
                ("4", 0) => "7",
                ("4", 1) => "5",
                ("5", 0) => "2",
                ("5", 1) => "6",
                ("6", 0) => "6",
                ("6", 1) => "4",
                ("7", 0) => "6",
                ("7", 1) => "2",
                )
    fsm = FSMIndiv(ikey, start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    sc.gid = 8
    mutator = LingPredMutator()
    n = 4
    for i in 1:n
        fsm = changelabel(rng, sc, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 8
    @test length(fsm.links) == 16
    @test links == fsm.links
end

@testset "randmix" begin
    ikey = IndivKey(:randmix, 1)
    start = "1"
    curr = "1"
    ones = Set(["1", "2", "6"])
    zeros = Set(["3", "4", "5"])
    links = LinkDict(
                ("1", 0) => "2",
                ("1", 1) => "3",
                ("2", 0) => "1",
                ("2", 1) => "4",
                ("3", 0) => "5",
                ("3", 1) => "6",
                ("4", 0) => "5",
                ("4", 1) => "6",
                ("5", 0) => "5",
                ("5", 1) => "6",
                ("6", 0) => "6",
                ("6", 1) => "6",
                )
    fsm = FSMIndiv(ikey, start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    sc.gid = 7
    mutator = LingPredMutator()
    n = 4
    for i in 1:n
        fsm = addstate(rng, sc, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 10
    @test length(fsm.links) == 20

    for i in 1:n
        fsm = rmstate(rng, sc, fsm)
    end

    @test length(union(fsm.ones, fsm.zeros)) == 6
    @test length(fsm.links) == 12

    for i in 1:n
        fsm = changelink(rng, sc, fsm)
    end

    for i in 1:n
        fsm = changelabel(rng, sc, fsm)
    end

    @test length(union(fsm.ones, fsm.zeros)) == 6
    @test length(fsm.links) == 12
    @test fsm.links != links
    @test fsm.ones != ones
    @test fsm.zeros != zeros
end


end