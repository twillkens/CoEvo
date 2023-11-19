export make_interaction_pairs, make_domains, make_environment_creators, make_interactions
export make_job_creator

function make_interaction_pairs(configuration::PredictionGameConfiguration)
    INTERACTION_PAIR_DICT = Dict(
        "two_species_control" => [["A", "B"]],
        "two_species_cooperative" => [["H", "M"]],
        "two_species_competitive" => [["P", "H"]],
        "three_species_control" => [["A", "B"],["B", "C"], ["C", "A"]],
        "three_species_mix" => [["H", "M"], ["P", "H"], ["M", "P"]],
        "three_species_cooperative" => [["A", "B"], ["C", "A"], ["B", "C"]],
        "three_species_competitive" => [["A", "B"], ["B", "C"], ["C", "A"]],
    )
    ecosystem_topology = configuration.ecosystem_topology
    if ecosystem_topology ∉ keys(INTERACTION_PAIR_DICT)
        throw(ArgumentError("Unrecognized ecosystem topology: $ecosystem_topology"))
    end
    interaction_pairs = INTERACTION_PAIR_DICT[ecosystem_topology]
    return interaction_pairs
end

function make_domains(configuration::PredictionGameConfiguration)
    DOMAIN_DICT = Dict(
        "two_species_control" => ["Control"],
        "two_species_cooperative" => ["Affinitive"],
        "two_species_competitive" => ["Adversarial"],
        "three_species_control" => ["Control", "Control", "Control"],
        "three_species_mix" => ["Affinitive", "Adversarial", "Avoidant"],
        "three_species_cooperative" => ["Affinitive", "Affinitive", "Avoidant"],
        "three_species_competitive" => ["Adversarial", "Adversarial", "Adversarial"],
    )
    ecosystem_topology = configuration.ecosystem_topology
    if ecosystem_topology ∉ keys(DOMAIN_DICT)
        throw(ArgumentError("Unrecognized ecosystem topology: $ecosystem_topology"))
    end
    domains = [PredictionGameDomain(domain) for domain in DOMAIN_DICT[ecosystem_topology]]
    return domains
end

function make_environment_creators(configuration::PredictionGameConfiguration)
    domains = make_domains(configuration)
    episode_length = configuration.episode_length
    communication_dimension = configuration.communication_dimension
    game = configuration.game
    if game == "continuous_prediction_game"
        environment_creator_type = ContinuousPredictionGameEnvironmentCreator
    elseif game == "collision_game"
        environment_creator_type = CollisionGameEnvironmentCreator
    else
        throw(ArgumentError("Unrecognized game: $game"))
    end
    environment_creators = [
        environment_creator_type(
            domain = domain,
            episode_length = episode_length,
            communication_dimension = communication_dimension
        )
        for domain in domains
    ]
    return environment_creators
end

function make_interactions(configuration::PredictionGameConfiguration)
    interaction_pairs = make_interaction_pairs(configuration)
    environment_creators = make_environment_creators(configuration)
    outcome_metrics = [
        environment_creator.domain.outcome_metric.name
        for environment_creator in environment_creators
    ]
    ids = [
        join([outcome_metric, interaction_pair...], "-") 
        for (interaction_pair, outcome_metric) in zip(interaction_pairs, outcome_metrics)
    ]
    interactions = [
        BasicInteraction(
            id = id,
            environment_creator = environment_creator,
            species_ids = interaction_pair,
            matchmaker = AllVersusAllMatchMaker(cohorts = configuration.cohorts),
        ) 
        for (id, environment_creator, interaction_pair) in 
            zip(ids, environment_creators, interaction_pairs)
    ]
    return interactions
end

function make_job_creator(configuration::PredictionGameConfiguration)
    interactions = make_interactions(configuration)
    job_creator = BasicJobCreator(
        n_workers = configuration.n_workers, interactions = interactions
    )
    return job_creator
end