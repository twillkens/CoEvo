#include("../../src/CoEvo.jl")
using .CoEvo

using Test

using Random: AbstractRNG
using StableRNGs: StableRNG
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
using .Metrics.Concrete.Common: AllSpeciesIdentity

@testset "Archivers" begin

@testset "BasicSpeciesCreator" begin
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
        evaluator = ScalarFitnessEvaluator(),
        replacer = GenerationalReplacer(),
        selector = FitnessProportionateSelector(n_parents = 2),
        recombiner = CloneRecombiner(),
        mutators = [IdentityMutator()],
    )
    species = create_species(species_creator, rng, indiv_id_counter, gene_id_counter) 
    dummy_outcomes = generate_nested_dict(n_pop, n_pop)
    evaluation = create_evaluation(species_creator.evaluator, rng, species, dummy_outcomes)
    reporter = BasicReporter(metric = AllSpeciesIdentity())
    species_evaluations = Dict(species => evaluation)
    measurement = measure(reporter, species_evaluations, Observation[])
    println(measurement)

end

end