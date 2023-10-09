#include("../../src/CoEvo.jl")
using .CoEvo
using Random
using StableRNGs: StableRNG
using Test
#using DataStructures

using .CoEvo.NSGAIIMethods: NSGAIIRecord, nsga_sort!, Max, Min, dominates
using .CoEvo.NSGAIIMethods: fast_non_dominated_sort!, crowding_distance_assignment!
using .CoEvo.Disco: Disco, get_derived_tests

@testset "NSGA-II" begin
println("Starting tests for NSGA-II and Disco...")

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
    tests1 = NSGAIIRecord(id = 1, tests = [1.0, 1.0, 1.0, 1.0])
    tests2 = NSGAIIRecord(id = 2, tests = [1.0, 1.0, 1.0, 0.0])
    tests3 = NSGAIIRecord(id = 3, tests = [1.0, 1.0, 0.0, 0.0])
    tests4 = NSGAIIRecord(id = 4, tests = [1.0, 0.0, 0.0, 0.0])
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
    tests1 =  NSGAIIRecord(id = 1, tests = [0.1710, 5.8290])
    tests2 =  NSGAIIRecord(id = 2, tests = [0.2180, 2.3470])
    tests3 =  NSGAIIRecord(id = 3, tests = [0.6690, 1.3960])
    tests4 =  NSGAIIRecord(id = 4, tests = [3.0110, 0.0700])
    tests5 =  NSGAIIRecord(id = 5, tests = [10.308, 1.4650])
    tests6 =  NSGAIIRecord(id = 6, tests = [1.6180, 10.708])
    tests7 =  NSGAIIRecord(id = 7, tests = [2.2750, 12.308])
    tests8 =  NSGAIIRecord(id = 8, tests = [3.3550, 14.682])
    tests9 =  NSGAIIRecord(id = 9, tests = [4.6710, 17.317])
    tests10 = NSGAIIRecord(id = 10,tests =  [16.854, 37.275])

    alltests = [tests1, tests2, tests3, tests4, tests5,
                tests6, tests7, tests8, tests9, tests10]
    pop = alltests
                                        
    sorted_pop = nsga_sort!(shuffle(pop), Min())
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

# @testset "Disco" begin
#     gen = 1
#     rng = StableRNG(42)
#     indiv_id_counter = Counter()
#     gene_id_counter = Counter()
#     species_id = "subjects"
#     n_pop = 10
# 
#     default_vector = collect(1:10)
# 
#     # Define species configuration similar to spawner
#     species_creator = BasicSpeciesCreator(
#         id = species_id,
#         n_pop = n_pop,
#         geno_creator = BasicVectorGenotypeCreator(
#             default_vector = default_vector
#         ),
#         phenotype_creator = DefaultPhenotypeCreator(),
#         evaluator = NSGAIIEvaluator(),
#         replacer = GenerationalReplacer(),
#         selector = FitnessProportionateSelector(n_parents = 2),
#         recombiner = CloneRecombiner(),
#         mutators = [IdentityMutator()],
#     )
#     species = create_species(species_creator, rng, indiv_id_counter, gene_id_counter) 
#     dummy_outcomes = generate_nested_dict(n_pop, n_pop)
#     evaluation = create_evaluation(species_creator.evaluator, rng, species, dummy_outcomes)
#     @test length(evaluation.disco_records) == n_pop
# end


@testset "nsga!-2" begin
    # source: https://www.ntnu.no/wiki/download/attachments/195538363/lecture%205.pdf?version=1&modificationDate=1598695184000&api=v2
    tests1 =  NSGAIIRecord(id = 1,  tests = [0.31, 6.10])
    tests2 =  NSGAIIRecord(id = 2,  tests = [0.43, 6.79])
    tests3 =  NSGAIIRecord(id = 3,  tests = [0.22, 7.09])
    tests4 =  NSGAIIRecord(id = 4,  tests = [0.59, 7.85])
    tests5 =  NSGAIIRecord(id = 5,  tests = [0.66, 3.65])
    tests6 =  NSGAIIRecord(id = 6,  tests = [0.83, 4.23])
    tests7 =  NSGAIIRecord(id = 7,  tests = [0.21, 5.90])
    tests8 =  NSGAIIRecord(id = 8,  tests = [0.79, 3.97])
    tests9 =  NSGAIIRecord(id = 9,  tests = [0.51, 6.51])
    tests10 = NSGAIIRecord(id = 10, tests = [0.27, 6.93])
    tests11 = NSGAIIRecord(id = 11, tests = [0.58, 4.52])
    tests12 = NSGAIIRecord(id = 12, tests = [0.24, 8.54])

    alltests = [tests1, tests2, tests3, tests4, tests5,
                tests6, tests7, tests8, tests9, tests10,
                tests11, tests12]
    pop = alltests

    function_minimiums = [0.1, 0.0]
    function_maximums = [1.0, 60.0]

    sortedpop = nsga_sort!(shuffle(pop), Min(), function_minimiums, function_maximums)
    front1 = [1, 2, 3]
    front2 = [4, 5, 6, 7]
    front3 = [8, 9, 10, 11]
    front4 = [12]

    @test pop[1].rank == 2
    @test round(pop[1].crowding, digits = 2) ≈ 0.63
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
    @test round(pop[10].crowding, digits = 2) ≈ 0.12
    @test findfirst(x -> x == pop[10], sortedpop) in front2

    @test pop[11].rank == 1
    @test findfirst(x -> x == pop[11], sortedpop) in front1

    @test pop[12].rank == 3
    @test findfirst(x -> x == pop[12], sortedpop) in front3

end

end
println("Finished tests for NSGA-II and Disco.")


outcomes_1 = Dict(
    4 => 1.0,
    5 => 0.0,
    6 => 0.0
)

outcomes_2 = Dict(
    4 => 0.8,
    5 => 0.0,
    6 => 0.0
)

outcomes_3 = Dict(
    4 => 0.0,
    5 => 0.0,
    6 => 1.0
)

outcomes_4 = Dict(
    4 => 0.7,
    5 => 0.0,
    6 => 0.9
)

outcomes_5 = Dict(
    4 => 0.0,
    5 => 1.0,
    6 => 0.0
)

outcomes_6 = Dict(
    4 => 0.0,
    5 => 1.0,
    6 => 0.0
)
outcomes = Dict(
    1 => outcomes_1,
    2 => outcomes_2,
    3 => outcomes_3,
    #4 => outcomes_4,
    #5 => outcomes_5,
    #6 => outcomes_6
)
using DataStructures: SortedDict

ids = [1, 2, 3]
#ids = [1, 2, 3, 4, 5, 6]
individual_tests = SortedDict{Int, Vector{Float64}}(
    id => [pair.second for pair in sort(collect(outcomes[id]), by = x -> x[1])]
    for id in keys(ids)
)

# println(individual_tests)
# tests = get_derived_tests(individual_tests, UInt32(32))
# println(tests)
end