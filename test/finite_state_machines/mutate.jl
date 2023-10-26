using Test

@testset "Mutation" begin

using Random
using StableRNGs
using StatsBase
using CoEvo
using .Counters.Basic: BasicCounter
using .Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using .Mutators.FiniteStateMachines: FiniteStateMachineMutator
using .Mutators.FiniteStateMachines: add_state, remove_state, change_link, change_label

@testset "add_state" begin
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

    fsm_before = FiniteStateMachineGenotype(start, ones, zeros, links)
    label = false
    truedest = 3
    falsedest = 5
    newstate = 6
    fsm = add_state(fsm_before, newstate, label, truedest, falsedest)

    @test fsm.start == 1
    @test length(fsm.links) == 12
    @test fsm.ones == Set([1, 2, 3, 4])
    @test fsm.zeros == Set([5, 6])
    expected = Dict{Tuple{Int, Bool}, Int}(
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

end

@testset "remove_state" begin
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

    fsm_before = FiniteStateMachineGenotype(start, ones, zeros, links)
    todelete = 3
    fsm = remove_state(fsm_before, todelete)

    @test fsm.start == 1
    @test length(fsm.links) == 8
    @test fsm.ones == Set([1, 2, 4])
    @test fsm.zeros == Set([5])
    expected = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 1,
        (2, 0) => 2,
        (2, 1) => 4,
        (4, 0) => 2,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 5,
    )
    @test fsm.links == expected
end

@testset "rmstate2" begin
    start = 1
    ones = Set([1, 2, 6])
    zeros = Set([3, 4, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 3,
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

    fsm_before = FiniteStateMachineGenotype(start, ones, zeros, links)

    todelete = 1
     newstart = 5
     fsm = remove_state(fsm_before, todelete, newstart)
 
     @test fsm.start == 5
     @test length(fsm.links) == 10
     @test fsm.ones == Set([2, 6])
     @test fsm.zeros == Set([3, 4, 5])
     expected = Dict{Tuple{Int, Bool}, Int}(
         (2, 0) => 3,
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
# 
@testset "change_link" begin
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

    fsm_before = FiniteStateMachineGenotype(start, ones, zeros, links)

    state = 3
    newdest = 1
    bit = true

    fsm = change_link(fsm_before, state, newdest, bit)

    @test fsm.start == 1
    @test length(fsm.links) == 12
    @test fsm.ones == Set([1, 2, 6])
    @test fsm.zeros == Set([3, 4, 5])
    expected = Dict{Tuple{Int, Bool}, Int}(
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

@testset "change_label" begin
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

    fsm_before = FiniteStateMachineGenotype(start, ones, zeros, links)

    state = 3

    fsm = change_label(fsm_before, state)

    @test fsm.start == 1
    @test length(fsm.links) == 12
    @test fsm.ones == Set([1, 2, 6, 3])
    @test fsm.zeros == Set([4, 5])
    @test fsm.links == links
end
# 
@testset "rand-add_state" begin
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
    fsm = FiniteStateMachineGenotype(start, ones, zeros, links)
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter(7)
    mutator = FiniteStateMachineMutator()

    n = 10
    for i in 1:n
        fsm = add_state(random_number_generator, gene_id_counter, fsm)
    end

    @test length(union(fsm.ones, fsm.zeros)) == 16
    @test length(fsm.links) == 32
    @test gene_id_counter.current_value == 17
end
# 
@testset "rand-remove_state" begin
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
    fsm = FiniteStateMachineGenotype(start, ones, zeros, links)
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter(8)
    n = 4
    for i in 1:n
        fsm = remove_state(random_number_generator, gene_id_counter, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 4
    @test length(fsm.links) == 8
    for i in 1:50
        fsm = remove_state(random_number_generator, gene_id_counter, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 1
    @test length(fsm.links) == 2
end
# 
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
    fsm = FiniteStateMachineGenotype(start, ones, zeros, links)
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter()
    n = 4
    for i in 1:n
        fsm = change_link(random_number_generator, gene_id_counter, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 8
    @test length(fsm.links) == 16
    @test links != fsm.links
end
# 
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
    fsm = FiniteStateMachineGenotype(start, ones, zeros, links)
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter()
    n = 4
    for i in 1:n
        fsm = change_label(random_number_generator, gene_id_counter, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 8
    @test length(fsm.links) == 16
    @test links == fsm.links
    @test fsm.ones != ones
    @test fsm.zeros != zeros
end
# 
@testset "randmix" begin
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
    fsm = FiniteStateMachineGenotype(start, ones, zeros, links)
    random_number_generator = StableRNG(42)
    gene_id_counter = BasicCounter(7)
    n = 4
    for i in 1:n
        fsm = add_state(random_number_generator, gene_id_counter, fsm)
    end
    @test length(union(fsm.ones, fsm.zeros)) == 10
    @test length(fsm.links) == 20

    for i in 1:n
        fsm = remove_state(random_number_generator, gene_id_counter, fsm)
    end

    @test length(union(fsm.ones, fsm.zeros)) == 6
    @test length(fsm.links) == 12

    for i in 1:n
        fsm = change_link(random_number_generator, gene_id_counter, fsm)
    end

    for i in 1:n
        fsm = change_label(random_number_generator, gene_id_counter, fsm)
    end

    @test length(union(fsm.ones, fsm.zeros)) == 6
    @test length(fsm.links) == 12
    @test fsm.links != links
    @test fsm.ones != ones
    @test fsm.zeros != zeros
end

end