using Test

@testset "Equals" begin

using Random
using StableRNGs
using CoEvo
#using .Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
#using .Genotypes.FiniteStateMachines: FiniteStateMachineGenotype
using .CoEvo.Concrete.Genotypes.FiniteStateMachines

@testset "basic equals" begin
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
    fsm1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    fsm2 = FiniteStateMachineGenotype(start, ones, zeros, links)
    @test fsm1 == fsm2
end

@testset "wrong start" begin
    start1 = 1
    start2 = 5
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
    fsm1 = FiniteStateMachineGenotype(start1, ones, zeros, links)
    fsm2 = FiniteStateMachineGenotype(start2, ones, zeros, links)
    @test fsm1 != fsm2
end

@testset "different link" begin 
    start = 1
    ones = Set([1, 2, 3, 4])
    zeros = Set([5])
    links1 = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 2,
        (2, 1) => 4,
        (3, 0) => 2,
        (3, 1) => 3,
        (4, 0) => 2,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 3, # different
    )
    links2 = Dict{Tuple{Int, Bool}, Int}(
        (1, 0) => 2,
        (1, 1) => 3,
        (2, 0) => 2,
        (2, 1) => 4,
        (3, 0) => 2,
        (3, 1) => 3,
        (4, 0) => 2,
        (4, 1) => 5,
        (5, 0) => 2,
        (5, 1) => 4, # different
    )
    fsm1 = FiniteStateMachineGenotype(start, ones, zeros, links1)
    fsm2 = FiniteStateMachineGenotype(start, ones, zeros, links2)
    @test fsm1 != fsm2
end

@testset "different size" begin
    start = 1
    ones1 = Set([1, 2, 3, 4])
    ones2 = Set([1, 2, 3, 4, 6])
    zeros = Set([5])
    links1 = Dict{Tuple{Int, Bool}, Int}(
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
    links2 = Dict{Tuple{Int, Bool}, Int}(
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
        (6, 0) => 2,
        (6, 1) => 3,
    )
    fsm1 = FiniteStateMachineGenotype(start, ones1, zeros, links1)
    fsm2 = FiniteStateMachineGenotype(start, ones2, zeros, links2)
    @test fsm1 != fsm2
end

@testset "different names still returns true" begin
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
    geno1 = FiniteStateMachineGenotype(start, ones, zeros, links)

    start = 6
    ones = Set([6, 7, 8, 9])
    zeros = Set([10])
    links = Dict{Tuple{Int, Bool}, Int}(
        (6, 0) => 7,
        (6, 1) => 8,
        (7, 0) => 7,
        (7, 1) => 9,
        (8, 0) => 7,
        (8, 1) => 8,
        (9, 0) => 7,
        (9, 1) => 10,
        (10, 0) => 7,
        (10, 1) => 8,
    )
    geno2 = FiniteStateMachineGenotype(start, ones, zeros, links)
    @test geno1 == geno2
end

@testset "sets of FiniteStateMachineGenotype" begin
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
    geno1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    geno2 = FiniteStateMachineGenotype(start, ones, zeros, links)
    @test Set([geno1, geno2]) == Set([geno1])
end

@testset "sets of FiniteStateMachineGenotype with different names" begin
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
    geno1 = FiniteStateMachineGenotype(start, ones, zeros, links)

    start = 6
    ones = Set([6, 7, 8, 9])
    zeros = Set([10])
    links = Dict{Tuple{Int, Bool}, Int}(
        (6, 0) => 7,
        (6, 1) => 8,
        (7, 0) => 7,
        (7, 1) => 9,
        (8, 0) => 7,
        (8, 1) => 8,
        (9, 0) => 7,
        (9, 1) => 10,
        (10, 0) => 7,
        (10, 1) => 8,
    )
    geno2 = FiniteStateMachineGenotype(start, ones, zeros, links)
    @test geno1 == geno2
    @test Set([geno1, geno2]) == Set([geno1])
end
end