using Test

@testset "NumbersGame" begin

println("Starting tests for NumbersGame...")

using StableRNGs: StableRNG
using CoEvo
using .Counters.Basic: BasicCounter
using .Genotypes.Vectors: BasicVectorGenotypeCreator
using .Individuals.Basic: BasicIndividualCreator
using .Phenotypes: Phenotype
using .Phenotypes.Defaults: DefaultPhenotypeCreator
using .Phenotypes.Vectors: BasicVectorPhenotype
using .Evaluators: create_evaluation
using .Evaluators.ScalarFitness: ScalarFitnessEvaluator, ScalarFitnessEvaluation
using .Replacers.Generational: GenerationalReplacer
using .Selectors.FitnessProportionate: FitnessProportionateSelector
using .Recombiners.Clone: CloneRecombiner
using .Mutators.Identity: IdentityMutator
using .SpeciesCreators: create_species
using .SpeciesCreators.Basic: BasicSpeciesCreator
using .Metrics.Evaluations: AllSpeciesFitness
using .Domains.NumbersGame: NumbersGameDomain
using .Environments: create_environment, get_outcome_set
using .Environments.Stateless: StatelessEnvironmentCreator
using .Reporters.Basic: BasicReporter
using .Ecosystems.Basic: BasicEcosystem, BasicEcosystemCreator
using .Configurations: make_ecosystem_creator, evolve!
using .Configurations.NumbersGame: NumbersGameConfiguration

"""
    NumbersGameProblem with Gradient

Test the `NumbersGameProblem` domain using the `Gradient` strategy. This set
confirms the outcomes when different phenotypes interact within the specified domain.
"""

 @testset "NumbersGameProblem with Gradient" begin
     phenoA = BasicVectorPhenotype([4])  # Vector representation
     phenoB = BasicVectorPhenotype([5])
     domain = NumbersGameDomain(:Gradient)
     env_creator = StatelessEnvironmentCreator(domain)
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
 
     @test outcome_set[1] == 0.0  # Assuming the first value is for A
     @test outcome_set[2] == 1.0  # Assuming the second value is for B
 
     Sₐ = [BasicVectorPhenotype(x) for x in [[1], [2], [3]]]  # Vector representation for each phenotype
     Sᵦ =  [BasicVectorPhenotype(x) for x in [[6], [7], [8]]]
 
     fitnessA = 0
     for other in Sₐ
         env = create_environment(env_creator, Phenotype[phenoA, other])
         outcome_set = get_outcome_set(env)
         fitnessA += outcome_set[1] == 1.0 ? 1 : 0
     end
     @test fitnessA == 3
 
     fitnessB = 0
     for other in Sᵦ
         env = create_environment(env_creator, Phenotype[phenoB, other])
         outcome_set = get_outcome_set(env)
         fitnessB += outcome_set[1] == 1.0 ? 1 : 0
     end
 
     @test fitnessB == 0
 end

 @testset "NumbersGameProblem with Focusing" begin
     phenoA = BasicVectorPhenotype([4, 16])  # Vector representation
     phenoB = BasicVectorPhenotype([5, 14])
     domain = NumbersGameDomain(:Focusing)
     env_creator = StatelessEnvironmentCreator(domain)
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 
     phenoB = BasicVectorPhenotype([5, 16])
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 0.0
 
     phenoA = BasicVectorPhenotype([5, 16, 8])
     phenoB = BasicVectorPhenotype([4, 16, 6])
     env = create_environment(env_creator, Phenotype[phenoA, phenoB])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 end
 
 @testset "NumbersGameProblem with Relativism" begin
     a = BasicVectorPhenotype([1, 6])
     b = BasicVectorPhenotype([4, 5])
     c = BasicVectorPhenotype([2, 4])
     domain = NumbersGameDomain(:Relativism)
     env_creator = StatelessEnvironmentCreator(domain)
 
     env = create_environment(env_creator, Phenotype[a, b])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 
     env = create_environment(env_creator, Phenotype[b, c])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 
     env = create_environment(env_creator, Phenotype[c, a])
     outcome_set = get_outcome_set(env)
     @test outcome_set[1] == 1.0
 end
 #
 
 @testset "BasicSpeciesCreator" begin
     gen = 1
     random_number_generator = StableRNG(42)
     individual_id_counter = BasicCounter()
     gene_id_counter = BasicCounter()
     species_id = "subjects"
     n_population = 10
 
     default_vector = collect(1:10)
 
     # Define species configuration similar to spawner
     species_creator = BasicSpeciesCreator(
         id = species_id,
         n_population = n_population,
         n_children = n_population,
         genotype_creator = BasicVectorGenotypeCreator(default_vector = default_vector),
         individual_creator = BasicIndividualCreator(),
         phenotype_creator = DefaultPhenotypeCreator(),
         evaluator = ScalarFitnessEvaluator(),
         replacer = GenerationalReplacer(),
         selector = FitnessProportionateSelector(n_parents = 2),
         recombiner = CloneRecombiner(),
         mutators = [IdentityMutator()],
     )
     species = create_species(
        species_creator, random_number_generator, individual_id_counter, gene_id_counter
    ) 
     dummy_outcomes = generate_nested_dict(n_population, n_population)
     evaluation = create_evaluation(
        species_creator.evaluator, random_number_generator, species, dummy_outcomes
    )

    @test typeof(evaluation) <: ScalarFitnessEvaluation
end

@testset "NumberGameConfiguration" begin
    configuration = NumbersGameConfiguration(n_population = 4)
    ecosystem_creator = make_ecosystem_creator(configuration)
    @test typeof(ecosystem_creator) <: BasicEcosystemCreator
    ecosystem = evolve!(configuration, n_generations = 10)
    @test typeof(ecosystem) <: BasicEcosystem
end

println("Finished tests for NumbersGame.")

end