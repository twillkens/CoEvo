include("../src/CoEvo.jl")
using .CoEvo
using Random
using StableRNGs: StableRNG
using Test
using DataStructures

function generate_nested_dict(first_layer_size::Int, second_layer_size::Int)
    # Initialize an empty dictionary
    my_dict = Dict{Int, Dict{Int, Float64}}()

    # Loop for the first layer
    for i in 1:first_layer_size
        # Initialize the second layer dictionary
        second_layer_dict = Dict{Int, Float64}()

        # Loop for the second layer
        for j in (11:(10 + second_layer_size))
            # Generate a random Float64 value between 0 and 1
            random_float = rand()

            # Add the random value to the second layer dictionary
            second_layer_dict[j] = random_float
        end

        # Add the second layer dictionary to the first layer
        my_dict[i] = second_layer_dict
    end
    
    return my_dict
end
@testset "Disco" begin
    
@testset "fast_non_dominated_sort!" begin
    tests1 = DiscoRecord(id = 1, derived_tests = [1.0, 1.0, 1.0, 1.0])
    tests2 = DiscoRecord(id = 2, derived_tests = [1.0, 1.0, 1.0, 0.0])
    tests3 = DiscoRecord(id = 3, derived_tests = [1.0, 1.0, 0.0, 0.0])
    tests4 = DiscoRecord(id = 4, derived_tests = [1.0, 0.0, 0.0, 0.0])
    alltests = [tests1, tests2, tests3, tests4]
    records = [tests3, tests4, tests2, tests1]

    fast_non_dominated_sort!(records, Max())
    sort!(records, by = record -> record.rank, alg=Base.Sort.QuickSort)
    @test records[1].id == 1
    @test records[2].id == 2
    @test records[3].id == 3
    @test records[4].id == 4
end


@testset "nsga!-1" begin
    # source: https://www.ntnu.no/wiki/download/attachments/195538363/lecture%205.pdf?version=1&modificationDate=1598695184000&api=v2
    tests1 =  DiscoRecord(id = 1, derived_tests = [0.1710, 5.8290])
    tests2 =  DiscoRecord(id = 2, derived_tests = [0.2180, 2.3470])
    tests3 =  DiscoRecord(id = 3, derived_tests = [0.6690, 1.3960])
    tests4 =  DiscoRecord(id = 4, derived_tests = [3.0110, 0.0700])
    tests5 =  DiscoRecord(id = 5, derived_tests = [10.308, 1.4650])
    tests6 =  DiscoRecord(id = 6, derived_tests = [1.6180, 10.708])
    tests7 =  DiscoRecord(id = 7, derived_tests = [2.2750, 12.308])
    tests8 =  DiscoRecord(id = 8, derived_tests = [3.3550, 14.682])
    tests9 =  DiscoRecord(id = 9, derived_tests = [4.6710, 17.317])
    tests10 = DiscoRecord(id = 10,derived_tests =  [16.854, 37.275])

    alltests = [tests1, tests2, tests3, tests4, tests5,
                tests6, tests7, tests8, tests9, tests10]
    pop = alltests
                                        
    nsga!(shuffle(pop), Min())
    @test pop[1].rank == 1
    @test pop[1].crowding ≈ Inf16
    @test findfirst(x -> x == pop[1], pop) in [1, 2, 3, 4]
    @test pop[2].rank == 1
    @test round(pop[2].crowding, digits=3) ≈ 0.945
    @test findfirst(x -> x == pop[2], pop) in [1, 2, 3, 4]
    @test pop[3].rank == 1
    @test round(pop[3].crowding, digits=3) ≈ 1.379
    @test findfirst(x -> x == pop[3], pop) in [1, 2, 3, 4]
    @test pop[4].rank == 1
    @test pop[4].crowding ≈ Inf16
    @test findfirst(x -> x == pop[4], pop) in [1, 2, 3, 4]
    @test pop[5].rank == 2
    @test pop[5].crowding ≈ Inf16
    @test findfirst(x -> x == pop[5], pop) in [5]
    @test pop[6].rank == 2
    @test pop[6].crowding ≈ Inf16
    @test findfirst(x -> x == pop[6], pop) in [6]
    @test pop[7].rank == 3
    @test pop[7].crowding ≈ Inf16
    @test findfirst(x -> x == pop[7], pop) in [7]
    @test pop[8].rank == 4
    @test pop[8].crowding ≈ Inf16
    @test findfirst(x -> x == pop[8], pop) in [8]
    @test pop[9].rank == 5
    @test pop[9].crowding ≈ Inf16
    @test findfirst(x -> x == pop[9], pop) in [9]
    @test pop[10].rank == 6
    @test pop[10].crowding ≈ Inf16
    @test findfirst(x -> x == pop[10], pop) in [10]
end

@testset "Disco" begin
    gen = 1
    rng = StableRNG(42)
    indiv_id_counter = Counter()
    gene_id_counter = Counter()
    species_id = "subjects"
    n_pop = 10

    default_vector = collect(1:10)

    # Define species configuration similar to spawner
    species_creator = BasicSpeciesCreator(
        id = species_id,
        n_pop = n_pop,
        geno_creator = BasicVectorGenotypeCreator(
            default_vector = default_vector
        ),
        phenotype_creator = DefaultPhenotypeCreator(),
        evaluator = DiscoEvaluator(),
        replacer = GenerationalReplacer(),
        selector = FitnessProportionateSelector(n_parents = 2),
        recombiner = CloneRecombiner(),
        mutators = [IdentityMutator()],
    )
    species = create_species(species_creator, rng, indiv_id_counter, gene_id_counter) 
    dummy_outcomes = generate_nested_dict(n_pop, n_pop)
    evaluation = create_evaluation(species_creator.evaluator, species, dummy_outcomes)
    @test length(evaluation.disco_records) == n_pop
end


@testset "nsga!-2" begin
    # source: https://www.ntnu.no/wiki/download/attachments/195538363/lecture%205.pdf?version=1&modificationDate=1598695184000&api=v2
    tests1 =  DiscoRecord(id = 1,  derived_tests = [0.31, 6.10])
    tests2 =  DiscoRecord(id = 2,  derived_tests = [0.43, 6.79])
    tests3 =  DiscoRecord(id = 3,  derived_tests = [0.22, 7.09])
    tests4 =  DiscoRecord(id = 4,  derived_tests = [0.59, 7.85])
    tests5 =  DiscoRecord(id = 5,  derived_tests = [0.66, 3.65])
    tests6 =  DiscoRecord(id = 6,  derived_tests = [0.83, 4.23])
    tests7 =  DiscoRecord(id = 7,  derived_tests = [0.21, 5.90])
    tests8 =  DiscoRecord(id = 8,  derived_tests = [0.79, 3.97])
    tests9 =  DiscoRecord(id = 9,  derived_tests = [0.51, 6.51])
    tests10 = DiscoRecord(id = 10, derived_tests = [0.27, 6.93])
    tests11 = DiscoRecord(id = 11, derived_tests = [0.58, 4.52])
    tests12 = DiscoRecord(id = 12, derived_tests = [0.24, 8.54])

    alltests = [tests1, tests2, tests3, tests4, tests5,
                tests6, tests7, tests8, tests9, tests10,
                tests11, tests12]
    pop = alltests

    sortedpop = nsga!(shuffle(pop), Min())

    front1 = [1, 2, 3]
    front2 = [4, 5, 6, 7]
    front3 = [8, 9, 10, 11]
    front4 = [12]

    @test pop[1].rank == 2
    @test pop[1].crowding != Inf16
    @test pop[1].crowding > pop[10].crowding
    @test findfirst(x -> x == pop[1], sortedpop) in front2

    @test pop[2].rank == 3
    @test findfirst(x -> x == pop[2], sortedpop) in front3

    @test pop[3].rank == 2
    @test pop[3].crowding ≈ Inf16
    @test findfirst(x -> x == pop[3], sortedpop) in front2

    @test pop[4].rank == 4
    @test findfirst(x -> x == pop[4], sortedpop) in front4

    @test pop[5].rank == 1
    @test findfirst(x -> x == pop[5], sortedpop) in front1

    @test pop[6].rank == 3
    @test findfirst(x -> x == pop[6], sortedpop) in front3

    @test pop[7].rank == 1
    @test findfirst(x -> x == pop[7], sortedpop) in front1

    @test pop[8].rank == 2
    @test pop[8].crowding ≈ Inf16
    @test findfirst(x -> x == pop[8], sortedpop) in front2

    @test pop[9].rank == 3
    @test findfirst(x -> x == pop[9], sortedpop) in front3

    @test pop[10].rank == 2
    @test pop[10].crowding != Inf16
    @test findfirst(x -> x == pop[10], sortedpop) in front2

    @test pop[11].rank == 1
    @test findfirst(x -> x == pop[11], sortedpop) in front1

    @test pop[12].rank == 3
    @test findfirst(x -> x == pop[12], sortedpop) in front3

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
