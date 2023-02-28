using Test
using Random
using StableRNGs
include("../src/Coevolutionary.jl")
using .Coevolutionary

function dummy(key::String, X::Vector{Float64})
    cfg = DefaultBitstringConfig(width=10, default_val=false)
    geno = cfg(key)
    NSGAiiRecord(geno, X)
end

@testset "Disco" begin
    
@testset "fast_non_dominated_sort!" begin
    tests1 = [1.0, 1.0, 1.0, 1.0]
    tests2 = [1.0, 1.0, 1.0, 0.0]
    tests3 = [1.0, 1.0, 0.0, 0.0]
    tests4 = [1.0, 0.0, 0.0, 0.0]
    alltests = [tests1, tests2, tests3, tests4]
    pop = [dummy("dummy-$(i)", tests) for (i, tests) in enumerate(alltests)]
    pop = [pop[3], pop[4], pop[2], pop[1]]
    fast_non_dominated_sort!(pop, Max())
    @test pop[1].key == "dummy-1"
    @test pop[2].key == "dummy-2"
    @test pop[3].key == "dummy-3"
    @test pop[4].key == "dummy-4"
end


@testset "nsga!-1" begin
    # source: https://www.ntnu.no/wiki/download/attachments/195538363/lecture%205.pdf?version=1&modificationDate=1598695184000&api=v2
    t1 =  [0.1710, 5.8290]
    t2 =  [0.2180, 2.3470]
    t3 =  [0.6690, 1.3960]
    t4 =  [3.0110, 0.0700]
    t5 =  [10.308, 1.4650]
    t6 =  [1.6180, 10.708]
    t7 =  [2.2750, 12.308]
    t8 =  [3.3550, 14.682]
    t9 =  [4.6710, 17.317]
    t10 = [16.854, 37.275]

    alltests = [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10]

    pop = [dummy("dummy-$(i)", tests) for (i, tests) in enumerate(alltests)]
    fmins = [0.0, 0.0]
    fmaxes = [25.0, 49.0]
    #fmaxes = [16.854, 37.275]

    selector = NSGAiiSelector(0, 0, 0, true, fmins, fmaxes, Min())
                                        
    pop = nsga(selector, shuffle(pop))
    popdict = Dict([r.key => r for r in pop])
    d = popdict["dummy-1"]
    @test d.rank == 1
    @test d.crowding ≈ Inf16

    d = popdict["dummy-2"]
    @test d.rank == 1
    @test round(d.crowding, digits = 3) ≈ 0.945

    d = popdict["dummy-3"]
    @test d.rank == 1
    @test round(d.crowding, digits = 3) ≈ 1.379

    d = popdict["dummy-4"]
    @test d.rank == 1
    @test d.crowding ≈ Inf16

    d = popdict["dummy-5"]
    @test d.rank == 2
    @test d.crowding ≈ Inf16

    d = popdict["dummy-6"]
    @test d.rank == 2
    @test d.crowding ≈ Inf16

    d = popdict["dummy-7"]
    @test d.rank == 3
    @test d.crowding ≈ Inf16

    d = popdict["dummy-8"]
    @test d.rank == 4
    @test d.crowding ≈ Inf16

    d = popdict["dummy-9"]
    @test d.rank == 5
    @test d.crowding ≈ Inf16

    d = popdict["dummy-10"]
    @test d.rank == 6 
    @test d.crowding ≈ Inf16
end

@testset "nsga!-2" begin
    # source: https://www.ntnu.no/wiki/download/attachments/195538363/lecture%205.pdf?version=1&modificationDate=1598695184000&api=v2
    t1 =  [0.31, 6.10]
    t2 =  [0.43, 6.79]
    t3 =  [0.22, 7.09]
    t4 =  [0.59, 7.85]
    t5 =  [0.66, 3.65]
    t6 =  [0.83, 4.23]
    t7 =  [0.21, 5.90]
    t8 =  [0.79, 3.97]
    t9 =  [0.51, 6.51]
    t10 = [0.27, 6.93]
    t11 = [0.58, 4.52]
    t12 = [0.24, 8.54]

    ks = ["1", "2", "3", "4", "5", "6", "a", "b", "c", "d", "e", "f"]
    alltests = [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12]
    pop = [dummy(k, t) for (i, (k, t)) in enumerate(zip(ks, alltests))]
    fmins = [0.1, 1.0]
    fmaxes = [1.0, 60.0]
                                        
    selector = NSGAiiSelector(0, 0, 0, false, fmins, fmaxes, Min())
    pop = nsga(selector, shuffle(pop))

    popdict = Dict([r.key => r for r in pop])

    d = popdict["1"]
    @test d.rank == 2
    @test round(d.crowding, digits = 2) ≈ 0.63

    d = popdict["2"]
    @test d.rank == 3

    d = popdict["3"]
    @test d.rank == 2
    @test d.crowding ≈ Inf16

    d = popdict["4"]
    @test d.rank == 4 

    d = popdict["5"]
    @test d.rank == 1 

    d = popdict["6"]
    @test d.rank == 3 

    d = popdict["a"]
    @test d.rank == 1

    d = popdict["b"]
    @test d.rank == 2
    @test d.crowding ≈ Inf16

    d = popdict["c"]
    @test d.rank == 3

    d = popdict["d"]
    @test d.rank == 2
    @test round(d.crowding, digits=2) ≈ 0.12 

    d = popdict["e"]
    @test d.rank == 1

    d = popdict["f"]
    @test d.rank == 3

end

end

