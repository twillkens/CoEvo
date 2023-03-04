@testset "Mutation" begin

@testset "addstate" begin
    start = 1
    ones = Set([1, 2, 3, 4])
    zeros = Set([5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 2,
        (2, 1) => 4,
        (3, 0) => 2,
        (3, 1) => 3,
        (4, 0) => 2,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 3,
    )

    fsm_before = FSMGeno(start, ones, zeros, links)
    label = false
    truedest = 3
    falsedest = 5
    newstate = 6
    fsm = addstate(fsm_before, newstate, label, truedest, falsedest)

    @test fsm.start == 1
    @test length(fsm.links) == 12
    @test fsm.ones == Set([1, 2, 3, 4])
    @test fsm.zeros == Set([5, 6])
    expected = Dict{Tuple{Int,Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 2,
        (2, 1) => 4,
        (3, 0) => 2,
        (3, 1) => 3,
        (4, 0) => 2,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 3,
        (6, 0) => 5,
        (6, 1) => 3,
    )
    @test fsm.links == expected

    min1, mm = vminimize(fsm)

    @test min1.start == mm[1]
    @test length(min1.links) == 8
    @test min1.ones == Set([mm[1], mm[2], mm[4]])
    @test min1.zeros == Set([mm[5]])
    expected = Dict{Tuple{Int,Bool}, Int}(
        (mm[1], 0) => mm[2],
        (mm[1], 1) => mm[1],
        (mm[2], 0) => mm[2],
        (mm[2], 1) => mm[4],
        (mm[4], 0) => mm[2],
        (mm[4], 1) => mm[5],
        (mm[5], 0) => mm[2],
        (mm[5], 1) => mm[1],
    )
    @test min1.links == expected
end

@testset "rmstate" begin
    start = 1
    ones = Set([1, 2, 3, 4])
    zeros = Set([5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 2,
        (2, 1) => 4,
        (3, 0) => 2,
        (3, 1) => 3,
        (4, 0) => 2,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 3,
    )

    fsm_before = FSMGeno(start, ones, zeros, links)
    todelete = 3
    newlinks = Dict{Tuple{Int, Bool}, Int}(
        (1, 1) => 1,
        (5, 1) => 4,
    )
    newstart = 1
    fsm = rmstate(fsm_before, todelete, newstart, newlinks)

    @test fsm.start == 1
    @test length(fsm.links) == 8
    @test fsm.ones == Set([1, 2, 4])
    @test fsm.zeros == Set([5])
    expected = Dict{Tuple{Int,Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 1,
        (2, 0) => 2,
        (2, 1) => 4,
        (4, 0) => 2,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 4,
    )
    @test fsm.links == expected

    min1, mm = vminimize(fsm)

    @test min1.start == mm[1]
    @test length(min1.links) == 8
    @test min1.ones == Set([mm[1], mm[2], mm[4]])
    @test min1.zeros == Set([mm[5]])
end

@testset "rmstate2" begin
    start = 1
    ones = Set([1, 2, 6])
    zeros = Set([3, 4, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 1,
        (2, 1) => 4,
        (3, 0) => 5,
        (3, 1) => 6,
        (4, 0) => 5,
        (4, 1) => 6,
        (5, 0) => 5,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 6,
    )

    fsm_before = FSMGeno(start, ones, zeros, links)

    todelete = 1
    newlinks = Dict{Tuple{Int, Bool}, Int}(
        (2, 0) => 5,
    )
    newstart = 5
    fsm = rmstate(fsm_before, todelete, newstart, newlinks)

    @test fsm.start == 5
    @test length(fsm.links) == 10
    @test fsm.ones == Set([2, 6])
    @test fsm.zeros == Set([3, 4, 5])
    expected = Dict{Tuple{Int,Bool}, Int}(
        (2, 0) => 5,
        (2, 1) => 4,
        (3, 0) => 5,
        (3, 1) => 6,
        (4, 0) => 5,
        (4, 1) => 6,
        (5, 0) => 5,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 6,
    )
    @test fsm.links == expected
end

@testset "changelink" begin
    start = 1
    ones = Set([1, 2, 6])
    zeros = Set([3, 4, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 1,
        (2, 1) => 4,
        (3, 0) => 5,
        (3, 1) => 6,
        (4, 0) => 5,
        (4, 1) => 6,
        (5, 0) => 5,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 6,
    )

    fsm_before = FSMGeno(start, ones, zeros, links)

    state = 3
    newdest = 1
    bit = true

    fsm = changelink(fsm_before, state, newdest, bit)

    @test fsm.start == 1
    @test length(fsm.links) == 12
    @test fsm.ones == Set([1, 2, 6])
    @test fsm.zeros == Set([3, 4, 5])
    expected = Dict{Tuple{Int,Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 1,
        (2, 1) => 4,
        (3, 0) => 5,
        (3, 1) => 1,
        (4, 0) => 5,
        (4, 1) => 6,
        (5, 0) => 5,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 6,
    )
    @test fsm.links == expected
end

@testset "changelabel" begin
    start = 1
    ones = Set([1, 2, 6])
    zeros = Set([3, 4, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 1,
        (2, 1) => 4,
        (3, 0) => 5,
        (3, 1) => 6,
        (4, 0) => 5,
        (4, 1) => 6,
        (5, 0) => 5,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 6,
    )

    fsm_before = FSMGeno(start, ones, zeros, links)

    state = 3

    fsm = changelabel(fsm_before, state)

    @test fsm.start == 1
    @test length(fsm.links) == 12
    @test fsm.ones == Set([1, 2, 6, 3])
    @test fsm.zeros == Set([4, 5])
    @test fsm.links == links
end

@testset "rand-addstate" begin
    start = 1
    ones = Set([1, 2, 6])
    zeros = Set([3, 4, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 1,
        (2, 1) => 4,
        (3, 0) => 5,
        (3, 1) => 6,
        (4, 0) => 5,
        (4, 1) => 6,
        (5, 0) => 5,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 6,
    )
    fsm = FSMGeno(start, ones, zeros, links)
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
    @test sc.gid == 17
end

@testset "rand-rmstate" begin
    ikey = IndivKey(:randrmstate, 1)
    start = 0
    curr = 0
    ones = Set([0, 1, 3, 4, 5, 6, 7])
    zeros = Set([2])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0) => 1,
        (0, 1) => 5,
        (1, 0) => 6,
        (1, 1) => 2,
        (2, 0) => 0,
        (2, 1) => 2,
        (3, 0) => 2,
        (3, 1) => 6,
        (4, 0) => 7,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 4,
        (7, 0) => 6,
        (7, 1) => 2,
    )
    fsm = FSMGeno(start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    sc.gid = 8
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
    start = 0
    ones = Set([0, 1, 3, 4, 5, 6, 7])
    zeros = Set([2])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0) => 1,
        (0, 1) => 5,
        (1, 0) => 6,
        (1, 1) => 2,
        (2, 0) => 0,
        (2, 1) => 2,
        (3, 0) => 2,
        (3, 1) => 6,
        (4, 0) => 7,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 4,
        (7, 0) => 6,
        (7, 1) => 2,
    )
    fsm = FSMGeno(start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    n = 4
    for i in 1:n
        fsm = changelink(rng, sc, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 8
    @test length(fsm.links) == 16
    @test links != fsm.links
end

@testset "randchangelabel" begin
    start = 0
    ones = Set([0, 1, 3, 4, 5, 6, 7])
    zeros = Set([2])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, 0) => 1,
        (0, 1) => 5,
        (1, 0) => 6,
        (1, 1) => 2,
        (2, 0) => 0,
        (2, 1) => 2,
        (3, 0) => 2,
        (3, 1) => 6,
        (4, 0) => 7,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 4,
        (7, 0) => 6,
        (7, 1) => 2,
    )
    fsm = FSMGeno(start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    n = 4
    for i in 1:n
        fsm = changelabel(rng, sc, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 8
    @test length(fsm.links) == 16
    @test links == fsm.links
    @test fsm.ones != ones
    @test fsm.zeros != zeros
end

@testset "randmix" begin
    ikey = IndivKey(:randmix, 1)
    start = 1
    ones = Set([1, 2, 6])
    zeros = Set([3, 4, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 1,
        (2, 1) => 4,
        (3, 0) => 5,
        (3, 1) => 6,
        (4, 0) => 5,
        (4, 1) => 6,
        (5, 0) => 5,
        (5, 1) => 6,
        (6, 0) => 6,
        (6, 1) => 6,
    )
    fsm = FSMGeno(start, ones, zeros, links)
    rng = StableRNG(42)
    sc = SpawnCounter()
    sc.gid = 7
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