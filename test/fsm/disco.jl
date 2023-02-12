using LingPred
using Random
using Test
using DataStructures

function dummy(key::String, tests::Vector{Float64})
    start = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    fsm = FSM(key, false, start, ones, zeros, links)
    indiv = FSMIndividual(key, fsm, minimize(fsm), DiscoRecord())
    indiv.disco.derived_tests = tests
    indiv
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
    discos = [indiv.disco for indiv in pop]
    fast_non_dominated_sort!(discos, Max())
    sort!(pop, by=ind -> ind.disco.rank, alg=Base.Sort.QuickSort)
    @test pop[1].key == "dummy-1"
    @test pop[2].key == "dummy-2"
    @test pop[3].key == "dummy-3"
    @test pop[4].key == "dummy-4"
end


@testset "nsga!-1" begin
    # source: https://www.ntnu.no/wiki/download/attachments/195538363/lecture%205.pdf?version=1&modificationDate=1598695184000&api=v2
    tests1 =  [0.1710, 5.8290]
    tests2 =  [0.2180, 2.3470]
    tests3 =  [0.6690, 1.3960]
    tests4 =  [3.0110, 0.0700]
    tests5 =  [10.308, 1.4650]
    tests6 =  [1.6180, 10.708]
    tests7 =  [2.2750, 12.308]
    tests8 =  [3.3550, 14.682]
    tests9 =  [4.6710, 17.317]
    tests10 = [16.854, 37.275]

    alltests = [tests1, tests2, tests3, tests4, tests5,
                tests6, tests7, tests8, tests9, tests10]
    pop = [dummy("dummy-$(i)", tests) for (i, tests) in enumerate(alltests)]
                                        
    nsga!(shuffle(pop), Min())
    @test pop[1].disco.rank == 1
    @test pop[1].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[1], pop) in [1, 2, 3, 4]
    @test pop[2].disco.rank == 1
    @test pop[2].disco.crowding ≈ 0.945
    @test findfirst(x -> x == pop[2], pop) in [1, 2, 3, 4]
    @test pop[3].disco.rank == 1
    @test pop[3].disco.crowding ≈ 1.378
    @test findfirst(x -> x == pop[3], pop) in [1, 2, 3, 4]
    @test pop[4].disco.rank == 1
    @test pop[4].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[4], pop) in [1, 2, 3, 4]
    @test pop[5].disco.rank == 2
    @test pop[5].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[5], pop) in [5]
    @test pop[6].disco.rank == 2
    @test pop[6].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[6], pop) in [6]
    @test pop[7].disco.rank == 3
    @test pop[7].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[7], pop) in [7]
    @test pop[8].disco.rank == 4
    @test pop[8].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[8], pop) in [8]
    @test pop[9].disco.rank == 5
    @test pop[9].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[9], pop) in [9]
    @test pop[10].disco.rank == 6
    @test pop[10].disco.crowding ≈ Inf16
    @test findfirst(x -> x == pop[10], pop) in [10]
end

# @testset "nsga!-2" begin
#     # source: https://www.ntnu.no/wiki/download/attachments/195538363/lecture%205.pdf?version=1&modificationDate=1598695184000&api=v2
#     tests1 =  [0.31, 6.10]
#     tests2 =  [0.43, 6.79]
#     tests3 =  [0.22, 7.09]
#     tests4 =  [0.59, 7.85]
#     tests5 =  [0.66, 3.65]
#     tests6 =  [0.83, 4.23]
#     tests7 =  [0.21, 5.90]
#     tests8 =  [0.79, 3.97]
#     tests9 =  [0.51, 6.51]
#     tests10 = [0.27, 6.93]
#     tests11 = [0.58, 4.52]
#     tests12 = [0.24, 8.54]

#     alltests = [tests1, tests2, tests3, tests4, tests5,
#                 tests6, tests7, tests8, tests9, tests10,
#                 tests11, tests12]
#     pop = [dummy("dummy-$(i)", tests) for (i, tests) in enumerate(alltests)]
                                        
#     sortedpop = nsga!(shuffle(pop), Min())

#     front1 = [1, 2, 3]
#     front2 = [4, 5, 6, 7]
#     front3 = [8, 9, 10, 11]
#     front4 = [12]

#     @test pop[1].disco.rank == 2
#     # @test pop[1].disco.crowding ≈ 0.63 # the example sets the fmax arbitrarily to 1 and 60...
#     # our output is 1.86 vs 0.63, but the relationship and consequences are the same.
#     @test pop[1].disco.crowding != Inf16
#     @test pop[1].disco.crowding > pop[10].disco.crowding
#     @test findfirst(x -> x == pop[1], sortedpop) in front2

#     @test pop[2].disco.rank == 3
#     @test findfirst(x -> x == pop[2], sortedpop) in front3

#     @test pop[3].disco.rank == 2
#     @test pop[3].disco.crowding ≈ Inf16
#     @test findfirst(x -> x == pop[3], sortedpop) in front2

#     @test pop[4].disco.rank == 4
#     @test findfirst(x -> x == pop[4], sortedpop) in front4

#     @test pop[5].disco.rank == 1
#     @test findfirst(x -> x == pop[5], sortedpop) in front1

#     @test pop[6].disco.rank == 3
#     @test findfirst(x -> x == pop[6], sortedpop) in front3

#     @test pop[7].disco.rank == 1
#     @test findfirst(x -> x == pop[7], sortedpop) in front1

#     @test pop[8].disco.rank == 2
#     @test pop[8].disco.crowding ≈ Inf16
#     @test findfirst(x -> x == pop[8], sortedpop) in front2

#     @test pop[9].disco.rank == 3
#     @test findfirst(x -> x == pop[9], sortedpop) in front3

#     @test pop[10].disco.rank == 2
#     # @test pop[10].disco.crowding ≈ 0.12 # example output is 0.12
#     @test pop[10].disco.crowding != Inf16
#     @test findfirst(x -> x == pop[10], sortedpop) in front2

#     @test pop[11].disco.rank == 1
#     @test findfirst(x -> x == pop[11], sortedpop) in front1

#     @test pop[12].disco.rank == 3
#     @test findfirst(x -> x == pop[12], sortedpop) in front3

# end

end
