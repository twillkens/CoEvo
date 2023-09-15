
using Test
using CoEvo
include("../../run/analyze.jl")

function geno1()
    ones = Set([3])
    zeros = Set([1, 2])
    start = 1
    links = Dict{Tuple{Int, Bool}, Int}(
        (1, false) => 2,
        (1, true) => 1,
        (2, false) => 3,
        (2, true) => 3,
        (3, false) => 3,
        (3, true) => 2,
    )
    FSMGeno(start, ones, zeros, links)
end

function primegeno1()
    ones = Set(["3"])
    zeros = Set(["1", "2"])
    primes = Set(["1P", "2P", "3P"])
    start = "1"
    links = Dict(
        ("1", "1P") => "1P",
        ("1", "0") => "2P",
        ("2", "P") => "2P",
        ("2", "01") => "3P",
        ("3", "0P") => "3P",
        ("3", "1") => "2P",
    )
    FSMPrimeGeno(start, ones, zeros, primes, links)
end

function geno2()
    start = 1
    ones = Set([3, 2, 1])
    zeros = Set([4])
    links = Dict{Tuple{Int64, Bool}, Int64}(
        (1, 0) => 1,
        (1, 1) => 4, 
        (2, 0) => 1, 
        (2, 1) => 2, 
        (4, 0) => 4, 
        (4, 1) => 1, 
        (3, 0) => 2, 
        (3, 1) => 4, 
    )
    FSMGeno(start, ones, zeros, links)
end

function primegeno2()
    start = "1"
    ones = Set(["3", "2", "1"])
    zeros = Set(["4"])
    primes = Set(["1P", "2P", "3P", "4P"])
    links = Dict(
        ("1", "0P") => "1P",
        ("1", "1") => "4P",
        ("2", "0") => "1P",
        ("2", "1P") => "2P",
        ("4", "0P") => "4P",
        ("4", "1") => "1P",
        ("3", "0") => "2P",
        ("3", "1") => "4P",
        ("3", "P") => "3P",

    )
    FSMPrimeGeno(start, ones, zeros, primes, links)
end

function all_equal(a::FSMPrimeGeno, b::FSMPrimeGeno)
    return a.start == b.start &&
            a.ones == b.ones &&
            a.zeros == b.zeros &&
            a.primes == b.primes &&
            a.links == b.links
end

function all_equal(a::FSMGeno, b::FSMGeno)
    return a.start == b.start &&
            a.ones == b.ones &&
            a.zeros == b.zeros &&
            a.links == b.links
end

@testset "Prime" begin

# Generate two predefined graphs and test if the result of FSMPrimeGeno conversion is as expected
@testset "Convert" begin
    geno = geno1()
    prime_geno = FSMPrimeGeno(geno)
    expected = primegeno1()
    @test all_equal(prime_geno, expected)
    @test all_equal(geno, FSMGeno(prime_geno))

    geno = geno2()
    prime_geno = FSMPrimeGeno(geno)
    expected = primegeno2()
    @test all_equal(prime_geno, expected)
    @test all_equal(geno, FSMGeno(prime_geno))
end


end