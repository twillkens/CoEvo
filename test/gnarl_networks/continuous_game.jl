@testset "ContinuousGnarlNetworkGame" begin

# Mock the necessary parts
using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Domains.PredictionGame
using CoEvo.Concrete.Genotypes.GnarlNetworks
using CoEvo.Concrete.Phenotypes.Defaults
using CoEvo.Concrete.Environments.ContinuousPredictionGame

# Always Moving Forward Genotype
forward_genotype = GnarlNetworkGenotype(
    n_input_nodes = 2,
    n_output_nodes = 1,
    hidden_nodes = [],
    connections = [
        ConnectionGene(
            id = 1,
            origin = 0.0,  # Bias node
            destination = 1.0,  # Movement node
            weight = 10.0  # Strong positive weight to always move forward
        )
    ]
)

# Always Moving Backward Genotype
backward_genotype = GnarlNetworkGenotype(
    n_input_nodes = 2,
    n_output_nodes = 1,
    hidden_nodes = [],
    connections = [
        ConnectionGene(
            id = 2,
            origin = 0.0,  # Bias node
            destination = 1.0,  # Movement node
            weight = -10.0  # Strong negative weight to always move backward
        )
    ]
)

domain = PredictionGameDomain("Control")
creator = ContinuousPredictionGameEnvironmentCreator(
    domain = domain, 
    episode_length = 10, 
    communication_dimension = 0
)

phenotype_creator = DefaultPhenotypeCreator()
phenotype_1 = create_phenotype(phenotype_creator, forward_genotype)    
phenotype_2 = create_phenotype(phenotype_creator, backward_genotype)

@testset "create_environment" begin
    phenotypes = Phenotype[phenotype_1, phenotype_2]
    environment = create_environment(creator, phenotypes)

    @test environment.position_1 ≈ π
    @test environment.position_2 ≈ 0.0
    @test environment.timestep == 0
end

@testset "is_active" begin
    phenotypes = Phenotype[phenotype_1, phenotype_1]

    environment = create_environment(creator, phenotypes)

    # Initial condition, both are active
    @test is_active(environment) == true
    
    # Simulate till they complete the episode
    while is_active(environment)
        step!(environment)
    end
    
    @test is_active(environment) == false
end

#@testset "step!" begin
#    phenotypes = Phenotype[phenotype_1, phenotype_1]
#    environment = create_environment(creator, phenotypes)
#
#    initial_position_1 = environment.position_1
#    initial_position_2 = environment.position_2
#    step!(environment)
#
#    @test environment.position_1 ≈ initial_position_1 + tanh(10.0)
#    @test environment.position_2 ≈ initial_position_2 + tanh(10.0)
#
#    phenotypes = Phenotype[phenotype_1, phenotype_2]
#    environment = create_environment(creator, phenotypes)
#
#    initial_position_1 = environment.position_1
#    initial_position_2 = environment.position_2
#    step!(environment)
#
#    @test environment.position_1 ≈ initial_position_1 + tanh(10.0)
#    @test environment.position_2 ≈ initial_position_2 + tanh(-10.0)
#
#    phenotypes = Phenotype[phenotype_2, phenotype_2]
#    environment = create_environment(creator, phenotypes)
#
#    initial_position_1 = environment.position_1
#    initial_position_2 = environment.position_2
#    step!(environment)
#
#    @test environment.position_1 ≈ initial_position_1 + tanh(-10.0)
#    @test environment.position_2 ≈ initial_position_2 + tanh(-10.0)
#
#    phenotypes = Phenotype[phenotype_2, phenotype_1]
#    environment = create_environment(creator, phenotypes)
#
#    initial_position_1 = environment.position_1
#    initial_position_2 = environment.position_2
#    step!(environment)
#
#    @test environment.position_1 ≈ initial_position_1 + tanh(-10.0)
#    @test environment.position_2 ≈ initial_position_2 + tanh(10.0)
#end
#
#@testset "get_outcome_set" begin
#    creator = ContinuousPredictionGameEnvironmentCreator(
#        domain = PredictionGameDomain("Control"), 
#        episode_length = 10, 
#        communication_dimension = 0
#    )
#    phenotypes = Phenotype[phenotype_1, phenotype_1]
#    environment = create_environment(creator, phenotypes)
#
#    while is_active(environment)
#        step!(environment)
#    end
#
#    outcome_set = get_outcome_set(environment)
#    @test outcome_set == [1.0, 1.0]
#
#    creator = ContinuousPredictionGameEnvironmentCreator(
#        domain = PredictionGameDomain("Affinitive"), 
#        episode_length = 10, 
#        communication_dimension = 0
#    )
#    phenotypes = Phenotype[phenotype_1, phenotype_1]
#    environment = create_environment(creator, phenotypes)
#
#    while is_active(environment)
#        step!(environment)
#    end
#    outcome_set = get_outcome_set(environment)
#    @test outcome_set == [1.0, 1.0]
#
#    phenotypes = Phenotype[phenotype_2, phenotype_2]
#    environment = create_environment(creator, phenotypes)
#
#    while is_active(environment)
#        step!(environment)
#    end
#    outcome_set = get_outcome_set(environment)
#    @test outcome_set == [0.0, 0.0]
#
#    creator = ContinuousPredictionGameEnvironmentCreator(
#        domain = PredictionGameDomain("Adversarial"), 
#        episode_length = 10, 
#        communication_dimension = 0
#    )
#    phenotypes = Phenotype[phenotype_1, phenotype_1]
#    environment = create_environment(creator, phenotypes)
#
#    while is_active(environment)
#        step!(environment)
#    end
#    outcome_set = get_outcome_set(environment)
#    @test outcome_set == [1.0, 0.0]
#
#    phenotypes = Phenotype[phenotype_2, phenotype_2]
#    environment = create_environment(creator, phenotypes)
#
#    while is_active(environment)
#        step!(environment)
#    end
#    outcome_set = get_outcome_set(environment)
#    @test outcome_set == [0.0, 1.0]
#
#    creator = ContinuousPredictionGameEnvironmentCreator(
#        domain = PredictionGameDomain("Avoidant"), 
#        episode_length = 10, 
#        communication_dimension = 0
#    )
#    phenotypes = Phenotype[phenotype_1, phenotype_1]
#    environment = create_environment(creator, phenotypes)
#
#    while is_active(environment)
#        step!(environment)
#    end
#    outcome_set = get_outcome_set(environment)
#    @test outcome_set == [0.0, 0.0]
#
#    phenotypes = Phenotype[phenotype_2, phenotype_2]
#    environment = create_environment(creator, phenotypes)
#
#    while is_active(environment)
#        step!(environment)
#    end
#    outcome_set = get_outcome_set(environment)
#    @test outcome_set == [1.0, 1.0]
#end

end
