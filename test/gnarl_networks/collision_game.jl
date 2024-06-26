@testset "CollisionGame" begin

# Mock the necessary parts
using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Concrete.Domains.PredictionGame
using CoEvo.Concrete.Genotypes.GnarlNetworks
using CoEvo.Concrete.Phenotypes.Defaults
using CoEvo.Concrete.Environments.CollisionGame

# Always Moving Forward Genotype
forward_genotype = GnarlNetworkGenotype(
    n_input_nodes = 2,
    n_output_nodes = 2,
    hidden_nodes = [],
    connections = [
        ConnectionGene(
            id = 1,
            origin = 0.0,  # Bias node
            destination = 1.0,  # Forward movement node
            weight = 10.0  # Strong positive weight to always move forward
        )
    ]
)

# Always Moving Backward Genotype
backward_genotype = GnarlNetworkGenotype(
    n_input_nodes = 2,
    n_output_nodes = 2,
    hidden_nodes = [],
    connections = [
        ConnectionGene(
            id = 2,
            origin = 0.0,  # Bias node
            destination = 1.0,  # Backward movement node
            weight = -10.0  # Strong positive weight to always move backward
        )
    ]
)

domain = PredictionGameDomain("Control")
creator = CollisionGameEnvironmentCreator(
    domain = domain, 
    initial_distance = 5.0, 
    episode_length = 10
)

phenotype_creator = DefaultPhenotypeCreator()
phenotype_1 = create_phenotype(phenotype_creator, forward_genotype)    
phenotype_2 = create_phenotype(phenotype_creator, backward_genotype)


@testset "create_environment" begin
    phenotypes = Phenotype[phenotype_1, phenotype_2]
    environment = create_environment(creator, phenotypes)

    @test environment.position_1 == -2.5
    @test environment.position_2 == 2.5
    @test environment.last_communication_1 == 0.0
    @test environment.last_communication_2 == 0.0
    @test environment.maximum_distance == 25.0
    @test environment.timestep == 1
end

@testset "is_active" begin
    phenotypes = Phenotype[phenotype_1, phenotype_1]

    environment = create_environment(creator, phenotypes)

    # Initial condition, both are active
    @test is_active(environment) == true
    
    # Simulate till they collide
    while is_active(environment)
        step!(environment)
    end
    
    @test is_active(environment) == false
end

@testset "step!" begin
    phenotypes = Phenotype[phenotype_1, phenotype_1]
    environment = create_environment(creator, phenotypes)

    initial_position_1 = environment.position_1
    initial_position_2 = environment.position_2
    step!(environment)

    @test environment.position_1 == initial_position_1 + 1.0
    @test environment.position_2 == initial_position_2 - 1.0

    phenotypes = Phenotype[phenotype_1, phenotype_2]
    environment = create_environment(creator, phenotypes)

    initial_position_1 = environment.position_1
    initial_position_2 = environment.position_2
    step!(environment)

    @test environment.position_1 == initial_position_1 + 1.0
    @test environment.position_2 == initial_position_2 + 1.0

    phenotypes = Phenotype[phenotype_2, phenotype_2]
    environment = create_environment(creator, phenotypes)

    initial_position_1 = environment.position_1
    initial_position_2 = environment.position_2
    step!(environment)

    @test environment.position_1 == initial_position_1 - 1.0
    @test environment.position_2 == initial_position_2 + 1.0

    phenotypes = Phenotype[phenotype_2, phenotype_1]
    environment = create_environment(creator, phenotypes)

    initial_position_1 = environment.position_1
    initial_position_2 = environment.position_2
    step!(environment)

    @test environment.position_1 == initial_position_1 - 1.0
    @test environment.position_2 == initial_position_2 - 1.0
end

@testset "get_outcome_set" begin
    creator = CollisionGameEnvironmentCreator(
        domain = PredictionGameDomain("Control"), 
        initial_distance = 5.0, 
        episode_length = 10
    )
    phenotypes = Phenotype[phenotype_1, phenotype_1]
    environment = create_environment(creator, phenotypes)

    while is_active(environment)
        step!(environment)
    end

    outcome_set =  get_outcome_set(environment)
    @test outcome_set == [1.0, 1.0]


    creator = CollisionGameEnvironmentCreator(
        domain = PredictionGameDomain("Affinitive"), 
        initial_distance = 5.0, 
        episode_length = 10
    )
    phenotypes = Phenotype[phenotype_1, phenotype_1]
    environment = create_environment(creator, phenotypes)

    while is_active(environment)
        step!(environment)
    end
    outcome_set =  get_outcome_set(environment)
    @test outcome_set == [1.0, 1.0]

    phenotypes = Phenotype[phenotype_2, phenotype_2]
    environment = create_environment(creator, phenotypes)

    while is_active(environment)
        step!(environment)
    end
    outcome_set =  get_outcome_set(environment)
    @test outcome_set == [0.0, 0.0]

    creator = CollisionGameEnvironmentCreator(
        domain = PredictionGameDomain("Adversarial"), 
        initial_distance = 5.0, 
        episode_length = 10
    )
    phenotypes = Phenotype[phenotype_1, phenotype_1]
    environment = create_environment(creator, phenotypes)

    while is_active(environment)
        step!(environment)
    end
    outcome_set =  get_outcome_set(environment)
    @test outcome_set == [1.0, 0.0]

    phenotypes = Phenotype[phenotype_2, phenotype_2]
    environment = create_environment(creator, phenotypes)

    while is_active(environment)
        step!(environment)
    end
    outcome_set =  get_outcome_set(environment)
    @test outcome_set == [0.0, 1.0]

    creator = CollisionGameEnvironmentCreator(
        domain = PredictionGameDomain("Avoidant"), 
        initial_distance = 5.0, 
        episode_length = 10
    )
    phenotypes = Phenotype[phenotype_1, phenotype_1]
    environment = create_environment(creator, phenotypes)

    while is_active(environment)
        step!(environment)
    end
    outcome_set =  get_outcome_set(environment)
    @test outcome_set == [0.0, 0.0]

    phenotypes = Phenotype[phenotype_2, phenotype_2]
    environment = create_environment(creator, phenotypes)

    while is_active(environment)
        step!(environment)
    end
    outcome_set =  get_outcome_set(environment)
    @test outcome_set == [1.0, 1.0]
end

end