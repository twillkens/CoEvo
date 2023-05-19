using Test
using Random
using StableRNGs
using CoEvo
include("../modes/modes.jl")

@testset "MODES" begin
@testset "metrics" begin

    v1 = [
        VectorGeno(:A, 1, [1,2,3]),
        VectorGeno(:A, 1, [1,2,3]),
        VectorGeno(:A, 1, [1,2,3,4]),
        VectorGeno(:A, 1, [1,2,3,4]),
    ]

    v2 = [
        VectorGeno(:B, 1, [1,2,3,4]),
        VectorGeno(:B, 1, [1,2,3,4,5])
    ]

    v3 = [
        VectorGeno(:C, 1, [1,2,3]),
        VectorGeno(:C, 1, [1,2,3,4,5])
    ]

    vs = [v1, v2, v3]
    ss = [Set(v) for v in vs]

    @test getcomplexities(ss) == [4, 5, 5]
    @test getchanges(ss) == [2, 1, 1]
    @test getnovelties(ss) == [2, 1, 0]
end

@testset "ecology" begin
    v1 = [
        VectorGeno(:A, 1, [1,2,3]),
    ]
    v2 = [
        VectorGeno(:A, 1, [1,2,3]),
        VectorGeno(:A, 1, [1,2,3]),
    ]
    v3 = [
        VectorGeno(:A, 1, [1,2,3]),
        VectorGeno(:A, 1, [1,2,3]),
        VectorGeno(:A, 1, [1,2,3,4]),
        VectorGeno(:A, 1, [1,2,3,4]),
    ]
    v4 = [
        VectorGeno(:A, 1, [1,2,3]),
        VectorGeno(:A, 1, [1,2,3,4]),
        VectorGeno(:A, 1, [1,2,3,4,5]),
    ]

    v5 = [
        VectorGeno(:A, 1, [1,2,3]),
        VectorGeno(:A, 1, [1,2,3,4]),
        VectorGeno(:A, 1, [1,2,3,4]),
        VectorGeno(:A, 1, [1,2,3,4]),
    ]

    vs = [v1, v2, v3, v4, v5]
    ss = [Set(v) for v in vs]
    ecos = getecologies(vs, ss)
    @test ecos ≈ [
        1 * log(2,1),
        1 * log(2,1),
        0.5 * log(2, 2) + 0.5 * log(2, 2),
        1/3 * log(2, 3) + 1/3 * log(2, 3) + 1/3 * log(2, 3),
        1/4 * log(2, 4) + 3/4 * log(2, 4/3)
    ]

end
end